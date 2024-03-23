# frozen_string_literal: true

module Langchain::Tool
  class PaymentGateway < Base
    NAME = "payment_gateway"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    def charge_customer(customer_id:, amount:)
      true
    end

    def refund_customer(customer_id:, amount:)
      true
    end
  end
end
