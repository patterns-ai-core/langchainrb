# frozen_string_literal: true

module Langchain::Tool
  #
  # A tool that wraps the Ruby file system classes.
  #
  # Usage:
  #    file_system = Langchain::Tool::FileSystem.new
  #
  class FileSystem
    extend Langchain::ToolDefinition

    define_function :list_directory, description: "File System Tool: Lists out the content of a specified directory" do
      property :directory_path, type: "string", description: "Directory path to list", required: true
    end

    define_function :read_file, description: "File System Tool: Reads the contents of a file" do
      property :file_path, type: "string", description: "Path to the file to read from", required: true
    end

    define_function :write_to_file, description: "File System Tool: Write content to a file" do
      property :file_path, type: "string", description: "Path to the file to write", required: true
      property :content, type: "string", description: "Content to write to the file", required: true
    end

    def list_directory(directory_path:)
      Dir.entries(directory_path)
    rescue Errno::ENOENT
      "No such directory: #{directory_path}"
    end

    def read_file(file_path:)
      File.read(file_path)
    rescue Errno::ENOENT
      "No such file: #{file_path}"
    end

    def write_to_file(file_path:, content:)
      File.write(file_path, content)
    rescue Errno::EACCES
      "Permission denied: #{file_path}"
    end
  end
end
