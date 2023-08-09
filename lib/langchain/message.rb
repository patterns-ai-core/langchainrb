# frozen_string_literal: true

module Langchain
  class Message
    attr_reader :content, :additional_kwargs

    def initialize(content, additional_kwargs = nil)
      @content = content
      @additional_kwargs = additional_kwargs
    end

    def type
      raise NotImplementedError
    end

    def to_s
      content
    end

    def ==(other)
      to_json == other.to_json
    end

    def to_json(options = {})
      hash = {
        type: type,
        content: content
      }

      hash[:additional_kwargs] = additional_kwargs unless additional_kwargs.nil? || additional_kwargs.empty?

      hash.to_json
    end
  end

  class AIMessage < Message
    def type
      "ai"
    end
  end

  class HumanMessage < Message
    def type
      "human"
    end
  end

  class SystemMessage < Message
    def type
      "system"
    end
  end

  class FunctionMessage < Message
    def type
      "function"
    end
  end
end
