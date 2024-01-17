# frozen_string_literal: true

RSpec.describe Langchain::Thread do
  it "raises an error if messages array contains non-Langchain::Message instance(s)" do
    expect { described_class.new(messages: [Langchain::Message.new, "foo"]) }.to raise_error(ArgumentError)
  end
end
