# frozen_string_literal: true

RSpec.describe Langchain::Tool::Tavily do
  subject { described_class.new(api_key: "123") }

  let(:response) {
    "{\"query\":\"What's the height of Burj Khalifa?\",\"follow_up_questions\":null,\"answer\":\"The height of Burj Khalifa is 828 meters (2,717 feet).\"}"
  }

  describe "#search" do
    it "returns a response" do
      allow(Net::HTTP).to receive(:start).and_return(double(body: response))

      result = subject.search(
        query: "What's the height of Burj Khalifa?",
        max_results: 1,
        include_answer: true
      )
      expect(result).to be_a(Langchain::ToolResponse)
      expect(result.content).to eq(response)
    end
  end
end
