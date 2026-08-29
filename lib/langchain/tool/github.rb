# frozen_string_literal: true

module Langchain::Tool
  class Github
    # 1. Use the new Mixins (Replace inheritance)
    extend Langchain::ToolDefinition
    include Langchain::DependencyHelper

    # 2. Define the tool function using the DSL
    #    This automatically generates the "tool_functions" JSON for OpenAI!
    define_function :execute, description: "Interact with GitHub repositories" do
      property :action, type: "string", description: "Action to perform: 'list_issues', 'get_pull_request', or 'file_content'", enum: ["list_issues", "get_pull_request", "file_content"], required: true
      property :owner, type: "string", description: "Repository owner (e.g. 'rails')", required: true
      property :repo, type: "string", description: "Repository name (e.g. 'rails')", required: true
      property :limit, type: "integer", description: "Limit for issues (default 5)"
      property :number, type: "integer", description: "PR Number (required for get_pull_request)"
      property :path, type: "string", description: "File path (required for file_content)"
    end

    # 3. Initialize with Dependency Check
    def initialize(access_token:)
      depends_on "octokit"
      @client = Octokit::Client.new(access_token: access_token)
    end

    # 4. The Execute method (accepts keys matching the properties above)
    def execute(action:, owner:, repo:, limit: 5, number: nil, path: nil)
      Langchain.logger.debug("#{self.class} - Executing #{action} on #{owner}/#{repo}")

      result = case action
               when "list_issues"
                 list_issues(owner, repo, limit)
               when "get_pull_request"
                 get_pull_request(owner, repo, number)
               when "file_content"
                 file_content(owner, repo, path)
               else
                 "Error: Unknown action '#{action}'"
               end

      # 5. Use the helper method (matches Calculator pattern)
      tool_response(content: result)
    rescue Octokit::Error => e
      tool_response(content: "GitHub API Error: #{e.message}")
    end

    private

    def list_issues(owner, repo, limit)
      issues = @client.list_issues("#{owner}/#{repo}", state: 'open', per_page: limit)
      issues.map { |i| "##{i.number}: #{i.title} (by #{i.user.login})" }.join("\n")
    end

    def get_pull_request(owner, repo, number)
      return "Error: 'number' is required for get_pull_request" if number.nil?
      pr = @client.pull_request("#{owner}/#{repo}", number)
      "PR ##{pr.number}: #{pr.title}\nState: #{pr.state}\n\n#{pr.body}"
    end

    def file_content(owner, repo, path)
      return "Error: 'path' is required for file_content" if path.nil?
      content = @client.contents("#{owner}/#{repo}", path: path)
      Base64.decode64(content.content)
    end
  end
end