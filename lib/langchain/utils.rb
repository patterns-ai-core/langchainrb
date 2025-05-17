# frozen_string_literal: true

module Langchain
  module Utils
    # Ensure compatibility with `URI::RFC2396_PARSER` (Ruby 3.4+) and `URI::DEFAULT_PARSER` (<= 3.3).
    UriParser = defined?(URI::RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::DEFAULT_PARSER
  end
end
