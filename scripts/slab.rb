require_relative "methods"

class Slab
  class << self
    def create_post(access_token_slab, repo_name, external_id, latest_release, topic_id)
      # extract variables from latest_release
      release_hash = JSON.parse(latest_release.body)
      latest_release = release_hash.fetch("data").fetch("repository").fetch("latestRelease")
      title = Date.parse(latest_release.fetch("publishedAt")).strftime("%d-%m-%Y")
      release_tag = latest_release["tagName"]

      markdown_string = HelperMethods.create_markdown_string(latest_release, repo_name, release_tag)
      markdown_string = "# #{title} #{markdown_string}"

      query = " mutation {
              syncPost(
                  externalId: \"#{external_id}\"
                  content: \"#{markdown_string}\"
                  format: MARKDOWN
                  editUrl: \"https://\"
              )
              {title, id}
          }"

      uri = URI("https://api.slab.com/v1/graphql")
      res = HelperMethods.query_func(uri, access_token_slab, query)
      json_res = JSON.parse(res.body)
      post_id_var = json_res.dig("data", "syncPost", "id")

      query = " mutation {
              addTopicToPost(
                  postId: \"#{post_id_var}\"
                  topicId: \"#{topic_id}\"
              ) {
                  name
              }
          }"
      HelperMethods.query_func(uri, access_token_slab, query)
      # return response for syncPost query
      res
    end

    # update_post returns response from request to slab with updated markdown string
    def update_post(access_token_slab, repo_name, post_id, external_id, latest_release)
      # This script takes post content from slab, reformats the json to markdown
      # and adds new markdown all together, then sends it in a query to slab

      query = " query {
              post (id: \"#{post_id}\") {
                  content
              }
          }"
      uri = URI("https://api.slab.com/v1/graphql")
      res = HelperMethods.query_func(uri, access_token_slab, query)
      post_json = JSON.parse(res.body)
      post_content = JSON.parse(post_json.fetch("data").fetch("post").fetch("content"))
      markdown_string, post_title = HelperMethods.create_markdown_from_slabjson(post_content)

      # creates markdown string from new release
      release_hash = JSON.parse(latest_release.body)
      release_new = release_hash.fetch("data").fetch("repository").fetch("latestRelease")
      tag_name = release_new["tagName"]
      markdown_string_new = HelperMethods.create_markdown_string(release_new, repo_name, tag_name)

      # combine the post title, current post content and new post content, insert at top
      markdown_string = "#{post_title} #{markdown_string_new} #{markdown_string}"

      # --- REQUEST TO UPDATE POST WITH NEW MARKDOWN STRING ---
      query = " mutation {
              syncPost(
                  externalId: \"#{external_id}\"
                  content: \"#{markdown_string}\"
                  format: MARKDOWN
                  editUrl: \"https://\"
              )
              {title, id}
          }"
      uri = URI("https://api.slab.com/v1/graphql")
      HelperMethods.query_func(uri, access_token_slab, query)
    end

    # searches for a post with current date and returns id if found, otherwise nil
    def search_post_exists(access_token_slab, current_date, topic_id)
      query = " query {
              search (
                  query: \"#{current_date}\"
                  first: 100
                  types: POST
              ) {
                  edges {
                      node {
                          ... on PostSearchResult {
                              post {
                                  title, id, topics{
                                      id
                                  }
                              }
                          }
                      }
                  }
              }
          }"

      uri = URI("https://api.slab.com/v1/graphql")
      res = HelperMethods.query_func(uri, access_token_slab, query)
      json_res = JSON.parse(res.body)

      # Dig out the different edges
      edges = json_res.dig("data", "search", "edges")
      posts = []
      existing_post_id = nil

      # add each post to the array of posts
      edges.each_with_index do |edge, i|
        # add post
        posts.append(edge.dig("node", "post"))
        # save important attributes
        post_id = posts[i].fetch("id")
        post_title = posts[i].fetch("title")
        topics = posts[i].fetch("topics")
        # check if topics exists
        if !!topics && post_title == current_date
          # check each topic whether it's the right one
          topics.each do |topic|
            id = topic["id"]
            # break out of loop if the post with the right topic has been found
            if !!id && id == topic_id
              existing_post_id = post_id
              break
            end
          end
        end
        # break if post is found
        break if !!existing_post_id
      end
      existing_post_id
    end
  end
end
