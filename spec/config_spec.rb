# frozen_string_literal: true

RSpec.describe Langchain::Config do
  it "has a vectorsearch property" do
    expect(subject).to respond_to(:vectorsearch)
  end
end
