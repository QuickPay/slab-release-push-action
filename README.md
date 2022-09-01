# Slab-action 
## a quick rundown


The purpose of Slab-action is to automate the publishing of release notes from a GitHub repository to a post in a given topic on Slab. The post on Slab will be named after the date of publishing, in the format ‘DD-MM-YYYY’. For any repository that implements the Slab-action, the flow will be as follows:

1. When a new release is published on the repository, the workflow executes the `main.rb` script. The repository name and owner, as well as access tokens for both GitHub and Slab, are given as arguments.

2. The `main.rb` script will check whether or not a post exists with the current date as title.

   1. If a post with the title does not exist, a new post is created with the current date as title and the information from the release notes as its     content. Following this, the post is inserted into a given topic. This is all done through the `create_post` function in the `slab.rb` script. 
    
   2. If a post with the title does exist, the `update_post` function in `slab.rb` is called. The contents of the post are extracted and converted to the     MarkDown (MD) format by the `create_markdown_from_slabjson` and `create_markdown_string` in `methods.rb`, and finally the latest release and its           notes are queried from GitHub and merged with the previous contents of the existing Slab post. This allows us to have all releases on a given day           put into a single Slab post with that date in the title.
  
3. The changes are reflected on Slab, and the result of the syncPost mutations (GraphQL) that create/update posts on Slab will print their results to the terminal.

      ![The Architecture](/assets/images/slab-integration.jpg)

      <sub>A simple diagram of the architecture and flow</sub>

## Things to keep in mind:

The syncPost mutations that create and update the posts on Slab have their issues, so the following can prove problematic:

 1. Editing posts is out of the question through Slab’s site, due to the fact that we have to use syncPosts to insert content through the API, and syncPosts are unfortunately read-only.
It is ***mostly*** out of the question through the API, as you would have to: 

    1. Reliably identify the elements you would edit from the JSON-looking Delta format that a Slab Post content query returns.
    2. Edit the content. 
    3. Convert it to HTML or MarkDown.
    4. Call the syncPost mutation with the same externalId as the syncPost was created with, with the new content.

  This could be implemented in a later release, but it is advisable to simply wait for Slab to update their API, as the Slab-action would need refactoring   once this happens anyway.

 2. Converting the format that you get from querying the content of a post on Slab to MarkDown is a bit difficult, so writing the release notes (even in MarkDown) by hand can have weird consequences on the formatting of the resulting Slab post.

Both of the issues above can be easily fixed by auto-generating the release notes on GitHub. This ensures that links to pull requests and issues are written explicitly, so that they are properly translated to Slab. 

One issue that also persists is that there can only be one hyperlink per line of text. If two pull requests are linked alongside each other in one line, it will typically only be the last of the two that is represented by an actual hyperlink in the Slab post.

It is also good to note that the topicId is currently hardcoded, as the plan so far has been to gather all posts under a single topic. Should this change, then some fucntionality to identify the correct topic should be introduced, topicId saved as a variable and introduced to the `create_post` and `update_post` functions.

Last but not least, inserting an image into the release notes **will** break the Slab post entirely.
This is possible to fix by deleting the post and re-creating it, but it is inadvisable, as there is currently no way to tell the extent of the damage.




## Usage

    runs-on: ubuntu-latest
    steps:
      - name: this workflow creates/updates a on slab containing release information
        uses: Go-Go-Power-Rangers/slab-action@main
        with: 
          repo_name: ${{ github.event.repository.name }}
          repo_owner: ${{ github.repository_owner }}
          accessToken_slab: "${{ secrets.SLAB_TOKEN }}"
          accessToken_github: "bearer ${{ secrets.GITHUB_TOKEN }}"
          topic_id: "2w941vt0"
