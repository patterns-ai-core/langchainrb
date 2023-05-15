# frozen_string_literal: true

require "tempfile"

RSpec.describe Prompt::Base do
  subject { Prompt::PromptTemplate.new(template: "Tell me a {adjective} joke.", input_variables: ["adjective"]) }

  describe "#save" do
    let(:file_path) { Tempfile.new(["test_file", ".json"]).path }
    let(:invalid_file_path) { Tempfile.new(["test_file", ".txt"]).path }

    after(:each) do
      FileUtils.rm_rf(File.dirname(file_path))
      FileUtils.rm_rf(File.dirname(invalid_file_path))
      puts "deleted"
      puts File.dirname(invalid_file_path)
    end

    it "saves to a JSON file" do
      subject.save(file_path: file_path)

      expect(File.exist?(file_path)).to be_truthy
      expect(File.read(file_path)).to eq(subject.to_h.to_json)
    end

    it "raises an error for invalid file extension" do
      expect { subject.save(file_path: invalid_file_path) }.to raise_error(ArgumentError, /must be json/)
    end

    it "creates directory if it does not exist" do
      non_existent_dir = File.join(Dir.tmpdir, "non_existent_dir")
      subject.save(file_path: "#{non_existent_dir}/test_file.json")
      expect(File.exist?("#{non_existent_dir}/test_file.json")).to be_truthy
      expect(File.directory?(non_existent_dir)).to be_truthy
    end
  end
end
