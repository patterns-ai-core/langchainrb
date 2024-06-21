# frozen_string_literal: true

# RubyCodeInterpreter does not work with Ruby 3.3;
# https://github.com/ukutaht/safe_ruby/issues/4
if RUBY_VERSION <= "3.2"
  RSpec.describe Langchain::Tool::RubyCodeInterpreter do
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
end
