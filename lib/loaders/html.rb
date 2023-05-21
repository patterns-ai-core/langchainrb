# frozen_string_literal: true

require "open-uri"

module Loaders
  class HTML < Base
    # We only look for headings and paragraphs
    TEXT_CONTENT_TAGS = %w[h1 h2 h3 h4 h5 h6 p]

    #
    # This Loader parses URL into a text.
    # If you'd like to use it directly you can do so like this:
    # Loaders::URL.new("https://nokogiri.org/").load
    #
    def initialize(url)
      depends_on "nokogiri"
      require "nokogiri"

      @url = url
    end

    # Check that url is a valid URL
    def loadable?
      !!(@url =~ URI::DEFAULT_PARSER.make_regexp)
    end

    def load
      return unless response.status.first == "200"

      doc = Nokogiri::HTML(response.read)
      doc.css(TEXT_CONTENT_TAGS.join(",")).map(&:inner_text).join("\n\n")
    end

    def response
      @response ||= URI.parse(@url).open
    end
  end
end
