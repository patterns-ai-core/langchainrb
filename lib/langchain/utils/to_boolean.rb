# frozen_string_literal: true

module Langchain
  module Utils
    class ToBoolean
      TRUTHABLE_STRINGS = %w[1 true t yes y]
      private_constant :TRUTHABLE_STRINGS

      def to_bool(value)
        case value
        when String
          TRUTHABLE_STRINGS.include?(value.downcase)
        when Integer
          value == 1
        when TrueClass
          true
        when FalseClass
          false
        when Symbol
          to_bool(value.to_s)
        else
          false
        end
      end
    end
  end
end
