# frozen_string_literal: true

module Langchain::LLM
  class UnifiedParameters
    attr_reader :schema, :aliases, :parameters

    class Null < self
      def initialize
        super(schema: {})
      end
    end

    def initialize(schema:, aliases: {}, parameters: {})
      @schema = schema || {}
      @aliases = aliases || {}
      @parameters = to_params(parameters.to_h) if !parameters.to_h.empty?
    end

    def to_params(params = {})
      @parameters ||= params.slice(*schema.keys)
      @aliases.each do |new_key, existing_key|
        # favor existing keys in case of conflicts
        @parameters[existing_key] ||= params[new_key]
      end
      @parameters
    end

    def to_h
      @parameters.to_h
    end
  end
end
