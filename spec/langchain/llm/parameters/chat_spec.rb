# frozen_string_literal: true

RSpec.describe Langchain::LLM::Parameters::Chat do
  let(:aliases) do
    {max_tokens_supported: :max_tokens}
  end
  let(:valid_params) do
    {
      messages: [{role: "system", content: "You're too cool."}],
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
      tools: [{type: "function", function: {name: "Temp", parameters: {substance: "H20"}}}],
      tool_choice: "auto",
      logit_bias: {"2435": -100, "640": -100}
    }
  end

  describe ".call(params)" do
    it "filters parameters to those provided" do
      params_with_extras = valid_params.merge(blah: 1, beep: "beep", boop: "boop")
      expect(described_class.call(params_with_extras, aliases: aliases)).to match(
        messages: [{role: "system", content: "You're too cool."}],
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
        tools: [{type: "function", function: {name: "Temp", parameters: {substance: "H20"}}}],
        tool_choice: "auto",
        logit_bias: {"2435": -100, "640": -100}
      )
    end

    it "allows mapping of aliases" do
      aliases = {max_tokens_to_sample: :max_tokens}
      valid_params[:max_tokens] = nil
      valid_params[:max_tokens_to_sample] = 100
      expect(described_class.call(valid_params, aliases: aliases)[:max_tokens]).to eq(100)
    end
  end
end
