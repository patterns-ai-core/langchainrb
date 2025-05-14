# frozen_string_literal: true

RSpec.describe Langchain::Tool::RubyCodeInterpreter do
  describe "#execute" do
    it "executes the expression" do
      response = subject.execute(input: '"hello world".reverse!')
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq("dlrow olleh")
    end

    it "executes a more complicated expression" do
      code = <<~CODE
        def reverse(string)
          string.reverse!
        end

        reverse('hello world')
      CODE

      response = subject.execute(input: code)
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq("dlrow olleh")
    end
  end
end
