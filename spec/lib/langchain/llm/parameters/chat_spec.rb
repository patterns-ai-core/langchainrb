# frozen_string_literal: true

RSpec.describe Langchain::LLM::Parameters::Chat do
  let(:aliases) do
    {max_tokens_supported: :max_tokens}
  end
  let(:valid_params) do
    {
      system: "You are a cheerful happy chatbot",
      messages: [{role: "system", content: "You're too cool."}],
      model: "gpt-4",
      prompt: "How warm is your water?",
      response_format: "json_object",
      stop: "--STOP--",
      stream: true,
      max_tokens: 50,
      temperature: 1,
      top_p: 0.5,
      top_k: 2,
      frequency_penalty: 1,
      presence_penalty: 1,
      repetition_penalty: 1,
      seed: 1,
      store: false,
      tools: [{type: "function", function: {name: "Temp", parameters: {substance: "H20"}}}],
      tool_choice: "auto",
      logit_bias: {"2435": -100, "640": -100}
    }
  end

  it "does not cache schema between instances" do
    first = described_class.new
    first.update(version: {default: 1})
    second = described_class.new
    expect(first.schema).not_to eq(second.schema)
  end

  context "delegations" do
    it "filters parameters to those provided" do
      params_with_extras = valid_params.merge(blah: 1, beep: "beep", boop: "boop", store: true)
      chat_params = described_class.new
      chat_params.alias_field(:max_tokens, as: :max_tokens_to_sample)
      expect(chat_params.to_params(params_with_extras)).to match(
        system: "You are a cheerful happy chatbot",
        messages: [{role: "system", content: "You're too cool."}],
        model: "gpt-4",
        prompt: "How warm is your water?",
        response_format: "json_object",
        stop: "--STOP--",
        stream: true,
        max_tokens: 50,
        temperature: 1,
        top_p: 0.5,
        top_k: 2,
        frequency_penalty: 1,
        presence_penalty: 1,
        repetition_penalty: 1,
        seed: 1,
        store: true,
        tools: [{type: "function", function: {name: "Temp", parameters: {substance: "H20"}}}],
        tool_choice: "auto",
        logit_bias: {"2435": -100, "640": -100}
      )
    end

    it "allows mapping of aliases" do
      chat_params = described_class.new
      chat_params.alias_field(:max_tokens, as: :max_tokens_to_sample)
      valid_params[:max_tokens] = nil
      valid_params[:max_tokens_to_sample] = 100
      expect(chat_params.to_params(valid_params)[:max_tokens]).to eq(100)
    end
  end

  context "store parameter" do
    it "passes store parameter to to_params" do
      chat_params = described_class.new
      params = chat_params.to_params(store: true)
      expect(params[:store]).to eq(true)
    end

    it "defaults to nil" do
      chat_params = described_class.new
      params = chat_params.to_params({})
      expect(params[:store]).to be_nil
    end
  end
end
