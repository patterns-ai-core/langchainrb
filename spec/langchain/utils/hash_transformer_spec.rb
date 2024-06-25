RSpec.describe Langchain::Utils::HashTransformer do
  describe ".camelize_lower" do
    it "converts snake_case to camelCase" do
      expect(described_class.camelize_lower("example_key")).to eq("exampleKey")
      expect(described_class.camelize_lower("nested_key_example")).to eq("nestedKeyExample")
    end

    it "handles strings without underscores" do
      expect(described_class.camelize_lower("example")).to eq("example")
    end

    it "handles empty strings" do
      expect(described_class.camelize_lower("")).to eq("")
    end
  end

  describe ".deep_transform_keys" do
    it "transforms keys of a simple hash" do
      hash = {example_key: "value", another_key: "another_value"}
      result = described_class.deep_transform_keys(hash) { |key| described_class.camelize_lower(key.to_s).to_sym }

      expect(result).to eq({exampleKey: "value", anotherKey: "another_value"})
    end

    it "transforms keys of a nested hash" do
      hash = {example_key: {nested_key: "value"}}
      result = described_class.deep_transform_keys(hash) { |key| described_class.camelize_lower(key.to_s).to_sym }

      expect(result).to eq({exampleKey: {nestedKey: "value"}})
    end

    it "transforms keys of an array of hashes" do
      hash = {array_key: [{nested_key: "value"}, {another_key: "another_value"}]}
      result = described_class.deep_transform_keys(hash) { |key| described_class.camelize_lower(key.to_s).to_sym }

      expect(result).to eq({arrayKey: [{nestedKey: "value"}, {anotherKey: "another_value"}]})
    end

    it "handles arrays of non-hash elements" do
      hash = {array_key: ["string", 123, :symbol]}
      result = described_class.deep_transform_keys(hash) { |key| described_class.camelize_lower(key.to_s).to_sym }

      expect(result).to eq({arrayKey: ["string", 123, :symbol]})
    end

    it "handles non-hash, non-array values" do
      hash = {simple_key: "value"}
      result = described_class.deep_transform_keys(hash) { |key| described_class.camelize_lower(key.to_s).to_sym }

      expect(result).to eq({simpleKey: "value"})
    end

    it "handles empty hashes" do
      hash = {}
      result = described_class.deep_transform_keys(hash) { |key| described_class.camelize_lower(key.to_s).to_sym }

      expect(result).to eq({})
    end

    it "handles deeply nested structures" do
      hash = {level_one: {level_two: {level_three: {nested_key: "value"}}}}
      result = described_class.deep_transform_keys(hash) { |key| described_class.camelize_lower(key.to_s).to_sym }

      expect(result).to eq({levelOne: {levelTwo: {levelThree: {nestedKey: "value"}}}})
    end
  end
end
