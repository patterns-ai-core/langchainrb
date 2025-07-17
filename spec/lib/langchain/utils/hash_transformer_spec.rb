RSpec.describe Langchain::Utils::HashTransformer do
  describe ".symbolize_keys" do
    it "symbolizes string keys at the top level of the hash" do
      hash = {"name" => "Alice", "age" => 30}
      expected_hash = {name: "Alice", age: 30}
      expect(described_class.symbolize_keys(hash)).to eq(expected_hash)
    end

    it "symbolizes string keys in nested hashes" do
      hash = {
        "user" => {
          "name" => "Alice",
          "details" => {
            "age" => 30,
            "city" => "Wonderland"
          }
        }
      }
      expected_hash = {
        user: {
          name: "Alice",
          details: {
            age: 30,
            city: "Wonderland"
          }
        }
      }
      expect(described_class.symbolize_keys(hash)).to eq(expected_hash)
    end

    it "leaves keys that are already symbols unchanged" do
      hash = {:name => "Alice", "age" => 30}
      expected_hash = {name: "Alice", age: 30}
      expect(described_class.symbolize_keys(hash)).to eq(expected_hash)
    end

    it "leaves keys that cannot be symbolized unchanged" do
      hash = {Object.new => "value", "key" => "value"}
      key = hash.keys.find { |k| k.is_a?(Object) }
      expected_hash = {key => "value", :key => "value"}
      expect(described_class.symbolize_keys(hash)).to eq(expected_hash)
    end

    it "returns an empty hash if the input hash is empty" do
      hash = {}
      expected_hash = {}
      expect(described_class.symbolize_keys(hash)).to eq(expected_hash)
    end

    it "handles hashes with mixed key types" do
      hash = {"string_key" => "value", :symbol_key => "value"}
      expected_hash = {string_key: "value", symbol_key: "value"}
      expect(described_class.symbolize_keys(hash)).to eq(expected_hash)
    end
  end
end
