# frozen_string_literal: true

module Langchain
  class SystemMessage < Message
    def type
      "system"
    end
  end
end
