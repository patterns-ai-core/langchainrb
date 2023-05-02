# frozen_string_literal: true

RSpec.describe LLM::Cohere do
  let(:subject) { described_class.new(api_key: "123") }

  describe "#embed" do
    before do
      allow_any_instance_of(Cohere::Client).to receive(:embed).and_return(
        {
          "id" => "a86a12ca-7ce5-4433-b68a-4d8454b22de7",
          "texts" => ["Hello World"],
          "embeddings" => [[-1.5693359, -0.9458008, 1.9355469]]
        }
      )
    end
  
    it "returns an embedding"  do
      expect(subject.embed(text: "Hello World")).to eq([-1.5693359, -0.9458008, 1.9355469])
    end
  end

  describe "#complete" do
    before do
      allow_any_instance_of(Cohere::Client).to receive(:generate).and_return(
        {
          "id" => "812c650e-a0d0-4502-a084-45b0d32fcb9c",
          "generations" => [
            {
              "id" => "8b79fd4f-7c72-4e1d-97a1-3dbe49206db2",
              "text" => "\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning"
            }
          ],
          "prompt" => "What is the meaining of life?",
          "meta" => { "api_version" => { "version" => "1" } }
        }
      )
    end

    it "returns a completion" do
      expect(subject.complete(prompt: "Hello World")).to eq("\nWhat is the meaning of life? What is the meaning of life?\nWhat is the meaning")
    end
  end

  describe "#default_dimension" do
    it "returns the default dimension" do
      expect(subject.default_dimension).to eq(1024)
    end
  end
end
