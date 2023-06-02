# frozen_string_literal: true

RSpec.describe Tool::RubyCodeInterpreter do
  describe "#execute" do
    it "executes the expression" do
      expect(subject.execute(input: '"hello world".reverse!')).to eq("dlrow olleh")
    end

    it "executes a more complicated expression" do
      code = <<~CODE
        def reverse(string)
          string.reverse!
        end

        reverse('hello world')
      CODE

      expect(subject.execute(input: code)).to eq("dlrow olleh")
    end
  end
end
