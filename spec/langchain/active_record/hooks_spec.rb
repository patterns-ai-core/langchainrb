# frozen_string_literal: true

RSpec.describe Langchain::ActiveRecord::Hooks do
  let(:dummy_class) do
    class Dummy
      include Langchain::ActiveRecord::Hooks
    end
  end

  it "responds to instance methods" do
    expect(dummy_class.new).to respond_to(:upsert_to_vectorsearch)
    expect(dummy_class.new).to respond_to(:as_vector)
  end

  it "responds to class methods" do
    expect(dummy_class).to respond_to(:vectorsearch)
    expect(dummy_class).to respond_to(:similarity_search)
  end
end
