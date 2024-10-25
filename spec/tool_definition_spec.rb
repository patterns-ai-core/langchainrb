# frozen_string_literal: true

RSpec.describe Langchain::ToolDefinition do
  let(:dummy_class) do
    Class.new do
      extend Langchain::ToolDefinition

      def self.name
        "DummyTool"
      end
    end
  end

  describe "Module inclusion" do
    it "adds expected methods to the class" do
      expect(dummy_class).to respond_to(:define_function, :function_schemas, :tool_name)
    end
  end

  describe ".tool_name" do
    it "returns the correct snake_case name for simple class names" do
      expect(dummy_class.tool_name).to eq("dummy_tool")
    end

    it "returns the correct snake_case name for complex class names" do
      complex_class = Class.new do
        extend Langchain::ToolDefinition
        def self.name
          "Langchain::Tool::API1Interface"
        end
      end
      expect(complex_class.tool_name).to eq("langchain_tool_api1_interface")
    end
  end

  describe ".define_function" do
    it "raises an error when no properties are defined inside the block" do
      expect {
        dummy_class.define_function :empty_function, description: "An empty function" do
          # No properties defined
        end
      }.to raise_error(ArgumentError, "Function parameters must have at least one property defined within it, if a block is provided")
    end
  end

  describe Langchain::ToolDefinition::ParameterBuilder do
    let(:builder) { described_class.new(parent_type: "object") }

    it "aliases item to property" do
      expect(builder.method(:item)).to eq(builder.method(:property))
    end

    describe "#build" do
      it "creates properties with various types" do
        described_class::VALID_TYPES.each do |type|
          result = builder.build do
            property :prop, type: type
          end

          expect(result[:properties][:prop][:type]).to eq(type)
        end
      end

      it "handles required properties" do
        result = builder.build do
          property :required_prop, type: "string", required: true
        end

        expect(result[:required]).to eq(["required_prop"])
      end

      it "handles enum properties" do
        result = builder.build do
          property :enum_prop, type: "string", enum: ["option1", "option2", "option3"]
        end

        expect(result[:properties][:enum_prop][:enum]).to eq(["option1", "option2", "option3"])
      end

      it "correctly structures object properties" do
        result = builder.build do
          property :object_prop, type: "object" do
            property :string_prop, type: "string"
          end
        end

        object_builder = described_class.new(parent_type: "object")
        expected = object_builder.build do
          property :string_prop, type: "string"
        end

        expect(result[:properties][:object_prop][:properties]).to eq(expected[:properties])
      end

      it "correctly structures array items" do
        result = builder.build do
          property :array_prop, type: "array" do
            item type: "string"
          end
        end

        array_builder = described_class.new(parent_type: "array")
        expected = array_builder.build do
          item type: "string"
        end

        expect(result[:properties][:array_prop][:items]).to eq(expected)
      end
    end

    describe "error handling" do
      it "raises an error for missing property name in object" do
        expect {
          builder.build do
            property type: "string"
          end
        }.to raise_error(ArgumentError, "Name must be provided for properties of an object")
      end

      it "raises an error for non-symbol property name" do
        expect {
          builder.build do
            property "string_prop", type: "string"
          end
        }.to raise_error(ArgumentError, "Invalid name 'string_prop'. Name must be a symbol")
      end

      it "raises an error for invalid property type" do
        expect {
          builder.build do
            property :invalid_prop, type: "invalid_type"
          end
        }.to raise_error(ArgumentError, /Invalid type 'invalid_type'/)
      end

      it "raises an error for invalid enum" do
        expect {
          builder.build do
            property :enum_prop, type: "string", enum: "option1, option2, option3"
          end
        }.to raise_error(ArgumentError, "Invalid enum 'option1, option2, option3'. Enum must be nil or an array")
      end

      it "raises an error for invalid required value" do
        expect {
          builder.build do
            property :required_prop, type: "string", required: "true"
          end
        }.to raise_error(ArgumentError, "Invalid required 'true'. Required must be a boolean")
      end

      it "raises an error for empty object properties" do
        expect {
          builder.build do
            property :object_prop, type: "object" do
              # No properties defined
            end
          end
        }.to raise_error(ArgumentError, "Object properties must have at least one property defined within it")
      end

      it "raises an error for empty array properties" do
        expect {
          builder.build do
            property :array_prop, type: "array" do
              # No items defined
            end
          end
        }.to raise_error(ArgumentError, "Array properties must have at least one item defined within it")
      end
    end
  end

  describe Langchain::ToolDefinition::FunctionSchemas do
    let(:tool_name) { "test_tool" }
    subject(:function_schemas) { described_class.new(tool_name) }

    describe "#initialize" do
      it "creates an instance with an empty schemas hash" do
        expect(function_schemas.instance_variable_get(:@schemas)).to eq({})
      end

      it "sets the tool name" do
        expect(function_schemas.instance_variable_get(:@tool_name)).to eq("test_tool")
      end
    end

    describe "#add_function" do
      context "when adding a function without parameters" do
        it "adds a function to the schemas" do
          function_schemas.add_function(method_name: :test_method, description: "Test description")
          expect(function_schemas.instance_variable_get(:@schemas)).to have_key(:test_method)
        end

        it "creates a correct schema structure" do
          function_schemas.add_function(method_name: :test_method, description: "Test description")
          schema = function_schemas.instance_variable_get(:@schemas)[:test_method]
          expect(schema[:type]).to eq("function")
          expect(schema[:function][:name]).to eq("test_tool__test_method")
          expect(schema[:function][:description]).to eq("Test description")
          expect(schema[:function][:parameters]).to be_nil
        end
      end

      context "when adding a function with parameters" do
        it "adds a function with parameters to the schemas" do
          function_schemas.add_function(method_name: :test_method, description: "Test description") do
            property :test_prop, type: "string", description: "Test property"
          end
          schema = function_schemas.instance_variable_get(:@schemas)[:test_method]
          expect(schema[:function][:parameters]).to be_a(Hash)
          expect(schema[:function][:parameters][:properties]).to have_key(:test_prop)
        end

        it "raises an error when no properties are defined in the block" do
          expect {
            function_schemas.add_function(method_name: :test_method, description: "Test description") do
              # Empty block
            end
          }.to raise_error(ArgumentError, /Function parameters must have at least one property defined/)
        end
      end
    end

    describe "#functions" do
      before do
        function_schemas.add_function(method_name: :test_method, description: "Test description") do
          property :test_prop, type: "string", description: "Test property"
        end
      end

      it "returns an array of function schemas" do
        result = function_schemas.functions
        expect(result).to be_an(Array)
        expect(result.first[:type]).to eq("function")
        expect(result.first[:function]).to be_a(Hash)
      end
    end

    describe "#to_google_gemini_format" do
      before do
        function_schemas.add_function(method_name: :test_method, description: "Test description") do
          property :test_prop, type: "string", description: "Test property"
        end
      end

      it "returns an array of function schemas without the type key" do
        result = function_schemas.to_google_gemini_format
        expect(result).to be_an(Array)
        expect(result.first).not_to have_key(:type)
        expect(result.first[:name]).to eq("test_tool__test_method")
      end
    end
  end
end
