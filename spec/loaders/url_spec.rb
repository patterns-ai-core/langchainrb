# frozen_string_literal: true

RSpec.describe Loaders::URL do
  let(:url) { "https://www.example.com" }
  let(:status) { ["200", "OK"] }
  let(:body) { "<html><body><h1>Lorem Ipsum</h1><p>Dolor sit amet.</p></body></html>" }
  let(:response) { double("response", status: status, read: body) }

  before do
    allow(URI).to receive(:parse).and_return(double(open: response))
  end

  describe "#load" do
    subject { described_class.new(url).load }

    context "successful response" do
      it "loads url" do
        expect(subject).to eq("Lorem Ipsum\n\nDolor sit amet.")
      end
    end

    context "error response" do
      let(:status) { ["404", "Not Found"] }
      let(:body) { "<html><body><h1>Not Found</h1></body></html>" }

      it "loads url" do
        expect(subject).to eq(nil)
      end
    end
  end

  describe "#loadable?" do
    subject { described_class.new(url).loadable? }

    context "with valid url" do
      it { is_expected.to be_truthy }
    end

    context "with invalid url" do
      let(:url) { "invalid url" }

      it { is_expected.to be_falsey }
    end
  end
end
