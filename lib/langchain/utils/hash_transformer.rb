module Langchain
  module Utils
    class HashTransformer
      def self.symbolize_keys(hash)
        hash.map do |k, v|
          new_key = begin
            k.to_sym
          rescue
            k
          end
          new_value = v.is_a?(Hash) ? symbolize_keys(v) : v
          [new_key, new_value]
        end.to_h
      end
    end
  end
end
