# frozen_string_literal: true

module Loaders
  module Processors
    class HTML
      EXTENSIONS = [".html", ".htm"]
      CONTENT_TYPES = ["text/html"]

      # We only look for headings and paragraphs
      TEXT_CONTENT_TAGS = %w[h1 h2 h3 h4 h5 h6 p]

      def initialize
        depends_on "nokogiri"
        require "nokogiri"
      end

      def parse(data)
        Nokogiri::HTML(data.read)
          .css(TEXT_CONTENT_TAGS.join(","))
          .map(&:inner_text)
          .join("\n\n")
      end
    end
  end
end
