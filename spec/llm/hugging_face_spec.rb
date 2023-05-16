# frozen_string_literal: true

require "hugging_face"

RSpec.describe LLM::HuggingFace do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#embed" do
    before do
      allow_any_instance_of(HuggingFace::InferenceApi).to receive(:embedding).and_return(
        [-1.5693359, -0.9458008, 1.9355469]
      )
    end

    it "returns an embedding" do
      expect(subject.embed(text: "Hello World")).to eq([-1.5693359, -0.9458008, 1.9355469])
    end
  end
end