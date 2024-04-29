# frozen_string_literal: true

module Langchain::LLM
  class UnifiedParameters
    include Enumerable

    attr_reader :schema, :aliases, :parameters

    class Null < self
      def initialize(parameters: {})
        super(schema: {}, parameters: parameters)
      end
    end

    def initialize(schema:, parameters: {})
      @schema = schema || {}
      @aliases = {}
      @schema.each do |name, param|
        @aliases[name] = Set.new(Array(param[:aliases])) if param[:aliases]
      end
      @parameters = to_params(parameters.to_h) if !parameters.to_h.empty?
    end

    def to_params(params = {})
      @parameters ||= params.slice(*schema.keys)
      @aliases.each do |field, aliased_keys|
        # favor existing keys in case of conflicts,
        # and check for multiples
        aliased_keys.each do |alias_key|
          @parameters[field] ||= params[alias_key]
        end
      end
      @parameters
    end

    def amend_schema(schema = {})
      @schema.merge!(schema)
      schema.each do |name, param|
        if param[:aliases]
          @aliases[name] ||= Set.new
          @aliases[name] << param[:aliases]
        end
      end
      self
    end

    def alias_field(field_name, as:)
      @aliases[field_name] ||= Set.new
      @aliases[field_name] << as
    end

    def to_h
      @parameters.to_h
    end

    def each(&)
      to_params.each(&)
    end

    def <=>(other)
      to_params.<=>(other.to_params)
    end

    def [](key)
      to_params[key]
    end
  end
end
