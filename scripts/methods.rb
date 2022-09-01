# release_body is json returned from github release
class HelperMethods
  class << self
    # creates markdown string from github release
    def create_markdown_string(release_description, repo_name, tag_name)
      markdown_string = ""
      ul_items = release_description["description"].split("\r").collect(&:strip)
      # put timestamp on title
      time = Time.now.getlocal.strftime("%l:%M %p")
      markdown_string += "\\n## #{repo_name} - #{tag_name} - *#{time}*\\n"

      ul_items.each do |i|
        # checks if any URI is present in string and inserts as markdown hyperlink
        ex_uri = URI.extract(i, %w[http https])
        if ex_uri.any?
          # assume ex_uri only has 1 uri per line
          normal_text = i.gsub(ex_uri[0].to_s, "")
          hyperlink = "[##{ex_uri[0].split("/")[-1]}](#{ex_uri[0]})"
          markdown_string += " - #{normal_text} #{hyperlink} \\n"
        else
          markdown_string += " - #{i} \\n"
        end
        ex_uri.clear
      end
      markdown_string
    end

    # returns post title and newly created markdown string from slab json content
    def create_markdown_from_slabjson(json_content)
      markdown_string = ""
      item_string = ""
      post_title = ""
      json_content.each do |item|
        if item.fetch("insert") == "\n"

          item_string += item.to_s
          item_string = " {\"item\"=>[#{item_string}]}"
          from_string = JSON.parse(item_string.gsub("=>", ":"))

          insert_text = []
          from_string["item"].each_with_index do |i, index|
            insert_text.append(i["insert"].to_s)

            # check if insert is a header
            if !!i["attributes"]["header"]
              case i["attributes"]["header"]
              # header 1 - return as post_title
              when 1
                post_title = "# #{insert_text[0]}"
                insert_text.delete_at(0)
              # header 2
              when 2
                insert_text[0] = "\\n## #{insert_text[0]}"
              end
            end
            # checks if insert text is bold
            insert_text[index] = "**#{i["insert"]}**" if !!i["attributes"]["bold"]
            # check if insert text is a link and creates hyperlink
            insert_text[index] = "[#{insert_text[index]}](#{i["attributes"]["link"]})" if !!i["attributes"]["link"]
            # check if insert text is italic
            insert_text[index] = "*#{i["insert"]}*" if !!i["attributes"]["italic"]
            # check if insert text is a bullet
            insert_text[0] = " - #{insert_text[0]}" if !!i["attributes"]["list"]
            # check if insert text is an indent (typically only with bullets)
            insert_text[0] = "    #{insert_text[0]}" if !!i["attributes"]["indent"]
          end

          markdown_string += insert_text.join.gsub("\n", "\\n")

          item_string = ""
        else
          item_string += "#{item},"
        end
      end
      [markdown_string, post_title]
    end

    # requests given URI with query (only for graphql api)
    def query_func(ex_uri, access_token, query)
      uri = ex_uri
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["Authorization"] = access_token
        req.body = JSON[{ "query" => query }]
        http.request(req)
      end
    end

    # gets latest release on github (uses queryFunc for request)
    def get_latest_release_github(access_token_github, repo_name, repo_owner)
      query = " query {
          repository(owner: \"#{repo_owner}\", name: \"#{repo_name}\") {
              latestRelease {
                  name
                  author
                      {name}
                  createdAt
                  publishedAt
                  description
                  tagName
              }
          }
      }"
      uri = URI("https://api.github.com/graphql")
      query_func(uri, access_token_github, query)
    end
  end
end
