require 'mail'
require 'uri'

module Langchain
  module Processors
    class Eml < Base
      EXTENSIONS    = ['.eml']
      CONTENT_TYPES = ['message/rfc822']

      def initialize(*)
        depends_on 'mail'
      end

      # Parse the document and return the cleaned text
      # @param [File] data
      # @return [String]
      def parse(data)
        mail         = Mail.read(data.path)
        text_content = extract_text_content(mail)
        clean_content(text_content)
      end

      private

      # Extract text content from the email, preferring plaintext over HTML
      def extract_text_content(mail)
        if mail.multipart?
          mail.parts.map { |part|
            if part.content_type.start_with?('text/plain')
              # Ensure the decoded content is treated as UTF-8
              part.body.decoded.force_encoding('UTF-8')
            elsif part.content_type.start_with?('multipart/alternative')
              subpart = part.parts.find { |subpart| subpart.content_type.start_with?('text/plain') }
              subpart&.body&.decoded&.force_encoding('UTF-8') if subpart
            end&.strip
          }.compact.join # Return the first non-nil content found
        else
          # Assume the whole email is in plain text and ensure UTF-8 encoding
          mail.body.decoded.force_encoding('UTF-8')
        end
      end

      # Clean and format the extracted content
      def clean_content(content)
        content
          .gsub(/\[cid:[^\]]+\]/, '')  # Remove embedded image references
          .gsub(URI.regexp(['http', 'https'])) { |match| "<#{match}>" }  # Format URLs
          .gsub(/\r\n?/, "\n")  # Normalize line endings to Unix style
          .gsub(/[\u200B-\u200D\uFEFF]/, '')  # Remove zero width spaces and similar characters
          .gsub(/<\/?[^>]+>/, '')  # Remove any HTML tags that might have sneaked in
      end
    end
  end
end