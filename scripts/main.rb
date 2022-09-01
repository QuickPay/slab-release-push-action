require "net/http"
require "json"
require "uri"
require "date"
require_relative "slab"
require_relative "methods"

repo_name = ARGV[0]
repo_owner = ARGV[1]
access_token_slab = ARGV[2]
access_token_github = ARGV[3]
topic_id = ARGV[4]

### The flow:
# 1. Check Slab for a post titled with currentDate, and either
# - 1a. Find nil, and create a new syncpost with currentDate as externalId
# - 1b. Find an existing post, extract the content with mads-json-dissection,
#       merge it with the new content, and override the syncPost by calling it
#       again with the new merged content.
###

latest_release = HelperMethods.get_latest_release_github(access_token_github, repo_name, repo_owner)

current_date = DateTime.now.strftime("%d-%m-%Y").to_s

existing_post_id = Slab.search_post_exists(access_token_slab, current_date, topic_id)
puts(existing_post_id)
res = if existing_post_id
        Slab.update_post(access_token_slab, repo_name, existing_post_id, current_date, latest_release)
      else
        Slab.create_post(access_token_slab, repo_name, current_date, latest_release, topic_id)
      end
puts("Finito! \nResponse from slab:\n#{res.inspect}")
