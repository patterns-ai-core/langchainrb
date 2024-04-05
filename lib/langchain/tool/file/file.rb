# frozen_string_literal: true

module Langchain::Tool
  class File < Base
    #
    # A tool that wraps the Ruby File class.
    #
    # Usage:
    #    file = Langchain::Tool::File.new
    #    file.execute(input: { operation: :read, file_path: "file.rb" })
    #    file.execute(input: { operation: :write, file_path: "file.rb", content: "file contents" })
    #
    NAME = "file"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    description <<~DESC
      A tool that wraps the Ruby File class, for interacting with the file system.
    DESC

    attr_reader :file_path, :operation, :content

    # Interacts with the file system using Ruby's File class
    #
    # @param input [Hash] file path, operation, and content
    # @return [String] file contents (if reading)
    def execute(input:)
      Langchain.logger.info("Executing \"#{input}\"", for: self.class)

      @operation = input[:operation]
      @file_path = input[:file_path]
      @content = input[:content]

      perform_operation
    rescue ArgumentError => e
      Langchain.logger.error(e.message, for: self.class)
    end

    private

    def perform_operation
      case operation
      when :read
        read_file
      when :write
        write_file
      else
        raise ArgumentError, "Invalid file operation: #{operation}"
      end
    end

    def read_file
      raise ArgumentError, "File not found: #{file_path}" unless ::File.exist?(file_path)
      ::File.read(file_path)
    end

    def write_file
      ::File.write(file_path, content)
    end
  end
end
