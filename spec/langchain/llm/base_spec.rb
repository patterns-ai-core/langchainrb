# frozen_string_literal: true

class TestLLM < Langchain::LLM::Base
end

class CustomTestLLM < Langchain::LLM::Base
  def initialize
    chat_parameters.update(version: {default: 1})
  end
end

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
    subject { TestLLM.new }

    it "returns an instance of ChatParameters" do
      chat_params = subject.chat_parameters
      expect(chat_params).to be_instance_of(Langchain::LLM::Parameters::Chat)
    end

    it "proxies the provided params to the UnifiedParameters" do
      chat_params = subject.chat_parameters({stream: true})
      expect(chat_params).to be_instance_of(Langchain::LLM::Parameters::Chat)
      expect(chat_params[:stream]).to be_truthy
    end

    it "does not cache between child instances" do
      expect(CustomTestLLM.new.chat_parameters.to_params).to include(version: 1)
      expect(TestLLM.new.chat_parameters.to_params).not_to include(version: 1)
    end
  end
end
