# frozen_string_literal: true

RSpec.describe Langchain::Tool::File do
  subject { described_class.new }

  describe "#execute" do
    let(:file_path) { "file.rb" }
    let(:content) { "file contents" }

    it "writes to a file" do
      input = {
        operation: :write,
        file_path: file_path,
        content: content
      }
      allow(File).to receive(:write).with(file_path, content)
      response = subject.execute(input: input)
      expect(response).to eq(nil)
    end

    it "reads a file" do
      input = {
        operation: :read,
        file_path: file_path
      }
      allow(File).to receive(:exist?).with(file_path).and_return(true)
      allow(File).to receive(:read).with(file_path).and_return(content)
      response = subject.execute(input: input)
      expect(response).to eq(content)
    end
  end
end
