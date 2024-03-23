# frozen_string_literal: true

require "mainstreet"

module Langchain::Tool
  class ShippingService < Base
    NAME = "shipping_service"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    def validate_address(address:)
      verifier = MainStreet::AddressVerifier.new(address)
      verifier.success? ? true : verifier.failure_message
    end

    def create_shipping_label(customer_name:, address:, provider:)
      validate_address(address: address)

      return "Invalid provider" unless ["ups", "fedex", "usps", "dhl"].include?(provider)

      true
    end

    def create_return_label(customer_name:, address:, provider:)
      validate_address(address)

      return "Invalid provider" unless ["ups", "fedex", "usps", "dhl"].include?(provider)

      true
    end
  end
end

# llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])

# assistant = Langchain::Assistant.new(
#   instructions: "You are an E-commerce Assistant GPT",
#   llm: llm,
#   tools: [
#     Langchain::Tool::InventoryManagement.new,
#     Langchain::Tool::ShippingService.new,
#     Langchain::Tool::PaymentGateway.new
#   ],
#   thread: Langchain::Thread.new
# )
