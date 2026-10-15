# frozen_string_literal: true

require "open3"

RSpec.describe Langchain do
  it "has a version number" do
    expect(Langchain::VERSION).not_to be nil
  end

  it "loads every class without Rails" do
    script = <<~RUBY
      require "langchain"
      abort "Rails was loaded" if defined?(Rails)
      Zeitwerk::Loader.eager_load_all
      print Langchain::LLM::OpenAI.name, " ", Langchain::LLM::Response::OpenAIResponse.name
    RUBY
    output, status = Open3.capture2e(RbConfig.ruby, "-I", Langchain.root.to_s, "-e", script)

    expect(status).to be_success, output
    expect(output).to eq("Langchain::LLM::OpenAI Langchain::LLM::Response::OpenAIResponse")
  end
end
