# frozen_string_literal: true

RSpec.describe Langchain::Tool::FileSystem do
  subject { described_class.new }

  context "directory operations" do
    let(:directory_path) { "directory/path" }
    let(:entries) { ["file1.txt", "file2.rb"] }

    it "lists a directory" do
      allow(Dir).to receive(:entries).with(directory_path).and_return(entries)
      response = subject.list_directory(directory_path: directory_path)
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq(entries)
    end

    it "returns a no such directory error" do
      allow(Dir).to receive(:entries).with(directory_path).and_raise(Errno::ENOENT)
      response = subject.list_directory(directory_path: directory_path)
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq("No such directory: #{directory_path}")
    end
  end

  context "file operations" do
    context "writes to a file" do
      let(:file_path) { "path/to/file.rb" }
      let(:content) { "file contents" }

      it "successfully writes" do
        allow(File).to receive(:write).with(file_path, content)
        response = subject.write_to_file(file_path: file_path, content: content)
        expect(response).to be_a(Langchain::ToolResponse)
        expect(response.content).to eq("File written successfully")
      end

      it "returns a permission denied error" do
        allow(File).to receive(:write).with(file_path, content).and_raise(Errno::EACCES)
        response = subject.write_to_file(file_path: file_path, content: content)
        expect(response).to be_a(Langchain::ToolResponse)
        expect(response.content).to eq("Permission denied: #{file_path}")
      end
    end

    context "reads a file" do
      let(:file_path) { "path/to/file.rb" }
      let(:content) { "file contents" }

      it "successfully reads" do
        allow(File).to receive(:read).with(file_path).and_return(content)
        response = subject.read_file(file_path: file_path)
        expect(response).to be_a(Langchain::ToolResponse)
        expect(response.content).to eq(content)
      end

      it "returns an error" do
        allow(File).to receive(:read).with(file_path).and_raise(Errno::ENOENT)
        response = subject.read_file(file_path: file_path)
        expect(response).to be_a(Langchain::ToolResponse)
        expect(response.content).to eq("No such file: #{file_path}")
      end
    end
  end
end
