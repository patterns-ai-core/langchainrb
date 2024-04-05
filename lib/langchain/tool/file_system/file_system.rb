# frozen_string_literal: true

module Langchain::Tool
  class FileSystem < Base
    #
    # A tool that wraps the Ruby file system classes.
    #
    # Usage:
    #    file_system = Langchain::Tool::FileSystem.new
    #
    NAME = "file_system"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    description <<~DESC
      A tool that wraps the Ruby File class, for interacting with the file system.
    DESC

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
    end
  end
end
