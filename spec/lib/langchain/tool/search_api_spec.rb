# frozen_string_literal: true

RSpec.describe Langchain::Tool::SearchApi do
  subject { described_class.new(api_key: "123") }

  let(:response) {
    {
      search_metadata: {id: "search_1", status: "Success"},
      search_parameters: {engine: "google", q: "What's the height of Burj Khalifa?"},
      answer_box: {type: "core_answer", answer: "828 m", thumbnail: "http://example.com/thumb.jpg"},
      organic_results: [
        {position: 1, title: "Burj Khalifa", link: "https://www.burjkhalifa.ae", snippet: "828 metres tall", favicon: "data:image/png;base64,AAAA"}
      ],
      pagination: {next: "https://www.searchapi.io/api/v1/search?page=2"}
    }.to_json
  }

  describe "#search" do
    let(:http) { double("http") }

    before do
      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(double(body: response))
    end

    it "sends the query, engine and options with the API key" do
      subject.search(query: "What's the height of Burj Khalifa?", num: 3, gl: "us")

      expect(http).to have_received(:request) do |request|
        expect(request.uri.to_s).to eq("https://www.searchapi.io/api/v1/search?engine=google&q=What%27s+the+height+of+Burj+Khalifa%3F&num=3&gl=us")
        expect(request["Authorization"]).to eq("Bearer 123")
      end
    end

    it "uses the engine it was initialized with" do
      described_class.new(api_key: "123", engine: "bing").search(query: "Burj Khalifa")

      expect(http).to have_received(:request) do |request|
        expect(request.uri.query).to eq("engine=bing&q=Burj+Khalifa")
      end
    end

    it "returns the results without metadata and images" do
      result = subject.search(query: "What's the height of Burj Khalifa?")

      expect(result).to be_a(Langchain::ToolResponse)
      expect(JSON.parse(result.content)).to eq(
        "answer_box" => {"type" => "core_answer", "answer" => "828 m"},
        "organic_results" => [
          {"position" => 1, "title" => "Burj Khalifa", "link" => "https://www.burjkhalifa.ae", "snippet" => "828 metres tall"}
        ]
      )
    end

    context "when SearchApi returns an error" do
      let(:response) { {error: "Invalid API key."}.to_json }

      it "returns the error" do
        result = subject.search(query: "Burj Khalifa")

        expect(result.content).to eq("SearchApi error: Invalid API key.")
      end
    end
  end
end
