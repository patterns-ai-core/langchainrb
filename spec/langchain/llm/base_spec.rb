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

  describe "#parameters_for(api_name, params = {})" do
    it "returns an instance of UnifiedParameters using the Chat schema by default" do
      chat_params = subject.parameters_for(:chat)
      expect(chat_params).to be_instance_of(Langchain::LLM::Parameters::Chat)
    end

    it "proxies the provided params to the UnifiedParameters" do
      chat_params = subject.parameters_for(:chat, {stream: true})
      expect(chat_params).to be_instance_of(Langchain::LLM::Parameters::Chat)
      expect(chat_params[:stream]).to be_truthy
    end

    it "returns a Langchain::LLM::Parameters::Null when the api_name is not registered" do
      expect(subject.parameters_for(:clams, {steam: true})).to be_instance_of(Langchain::LLM::UnifiedParameters::Null)
    end
  end
end
