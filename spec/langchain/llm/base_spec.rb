# frozen_string_literal: true

RSpec.describe Langchain::LLM::Base do
  let(:subject) { described_class.new }

  describe "#chat" do
    it "raises an error" do
      expect { subject.chat }.to raise_error(NotImplementedError)
    end
  end

  describe "#complete" do
    it "raises an error" do
      expect { subject.complete }.to raise_error(NotImplementedError)
    end
  end

  describe "#embed" do
    it "raises an error" do
      expect { subject.embed }.to raise_error(NotImplementedError)
    end
  end

  describe "#summarize" do
    it "raises an error" do
      expect { subject.summarize }.to raise_error(NotImplementedError)
    end
  end

  describe "#chat_parameters(params = {})" do
    it "returns an instance of UnifiedParameters with the unified Chat schema by default" do
      chat_params = subject.chat_parameters
      expect(chat_params).to be_instance_of(Langchain::LLM::UnifiedParameters)
    end

    it "proxies the provided params to the UnifiedParameters" do
      chat_params = subject.chat_parameters(stream: true)
      expect(chat_params[:stream]).to be_truthy
    end
  end
end
