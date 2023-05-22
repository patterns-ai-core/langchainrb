# frozen_string_literal: true

module Chunkers
  class MarkdownSplitter < TextSplitter
    MARKDOWN_DELIMITERS = [
      "\n## ",
      "\n### ",
      "\n#### ",
      "\n##### ",
      "\n###### ",
      "```\n\n",
      "\n\n***\n\n",
      "\n\n---\n\n",
      "\n\n___\n\n",
      "\n\n",
      "\n"
    ].freeze

    def initialize(**kwargs)
      super(delimeter: MARKDOWN_DELIMITERS, **kwargs)
    end
  end
end
