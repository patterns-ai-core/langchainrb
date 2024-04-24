# frozen_string_literal: true

RSpec.describe Langchain::Messages::GoogleGeminiMessage do
  it "raises an error if role is not one of allowed" do
    expect { described_class.new(role: "foo") }.to raise_error(ArgumentError)
  end
end
