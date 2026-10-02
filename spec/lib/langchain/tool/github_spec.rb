# frozen_string_literal: true

require "octokit"

RSpec.describe Langchain::Tool::Github do
  subject { described_class.new(access_token: "mock_token") }

  let(:octokit_client) { instance_double(Octokit::Client) }

  before do
    
    allow(Octokit::Client).to receive(:new).with(access_token: "mock_token").and_return(octokit_client)
  end

  describe "#execute" do
    context "when action is list_issues" do
      let(:issue) { double("Issue", number: 1, title: "Test Issue", user: double("User", login: "dev")) }

      it "returns a formatted list of issues" do
        allow(octokit_client).to receive(:list_issues).with("rails/rails", state: "open", per_page: 5).and_return([issue])

        # Note: We pass keywords now, not a JSON string, because define_function handles the parsing layer
        response = subject.execute(action: "list_issues", owner: "rails", repo: "rails", limit: 5)
        
        # Match the Calculator spec pattern
        expect(response).to be_a(Langchain::ToolResponse)
        expect(response.content).to include("#1: Test Issue (by dev)")
      end
    end

    context "when action is file_content" do
      let(:content) { double("Content", content: Base64.encode64("ruby content")) }

      it "returns the decoded file content" do
        allow(octokit_client).to receive(:contents).with("rails/rails", path: "Gemfile").and_return(content)

        response = subject.execute(action: "file_content", owner: "rails", repo: "rails", path: "Gemfile")
        
        expect(response).to be_a(Langchain::ToolResponse)
        expect(response.content).to eq("ruby content")
      end
    end

    context "when Octokit errors" do
      it "returns a clean error message" do
        allow(octokit_client).to receive(:list_issues).and_raise(Octokit::Error.new("Rate Limit"))

        response = subject.execute(action: "list_issues", owner: "rails", repo: "rails")
        
        expect(response.content).to include("GitHub API Error: Rate Limit")
      end
    end
  end
end