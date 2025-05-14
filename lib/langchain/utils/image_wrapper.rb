# frozen_string_literal: true

require "open-uri"
require "base64"

module Langchain
  module Utils
    class ImageWrapper
      attr_reader :image_url

      def initialize(image_url)
        @image_url = image_url
      end

      def base64
        @base64 ||= begin
          image_data = open_image.read
          Base64.strict_encode64(image_data)
        end
      end

      def mime_type
        # TODO: Make it work with local files
        open_image.meta["content-type"]
      end

      private

      def open_image
        # TODO: Make it work with local files
        uri = URI.parse(image_url)
        raise URI::InvalidURIError, "Invalid URL scheme" unless %w[http https].include?(uri.scheme)
        @open_image ||= URI.open(image_url) # rubocop:disable Security/Open
      end
    end
  end
end
