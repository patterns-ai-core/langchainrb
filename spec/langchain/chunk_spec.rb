# frozen_string_literal: true

RSpec.describe Langchain::Chunk do
  subject { described_class.new(text: "Hello World") }

  it "has a text" do
    expect(subject.text).to eq("Hello World")
  end
end
