# frozen_string_literal: true

module Langchain
  module Processors
    class Pptx < Base
      EXTENSIONS = [".pptx"]
      CONTENT_TYPES = ["application/vnd.openxmlformats-officedocument.presentationml.presentation"]

      def initialize(*)
        depends_on "power_point_pptx"
      end

      # Parse the document and return the text
      # @param [File] data
      # @return [String]
      def parse(data)
        presentation = PowerPointPptx::Document.open(data)

        slides = presentation.slides
        contents = slides.map(&:content)
        text = contents.map do |sections|
          sections.map(&:strip).join(" ")
        end

        text.join("\n\n")
      end
    end
  end
end
