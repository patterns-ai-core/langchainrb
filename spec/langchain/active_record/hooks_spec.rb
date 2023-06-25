# frozen_string_literal: true

class Dummy
  include Langchain::ActiveRecord::Hooks
end

RSpec.describe Langchain::ActiveRecord::Hooks do
  it "responds to instance methods" do
    expect(Dummy.new).to respond_to(:upsert_to_vectorsearch)
    expect(Dummy.new).to respond_to(:as_vector)
  end

  it "responds to class methods" do
    expect(Dummy).to respond_to(:vectorsearch)
    expect(Dummy).to respond_to(:similarity_search)
  end
end
