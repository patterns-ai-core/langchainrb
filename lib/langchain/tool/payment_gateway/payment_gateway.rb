# frozen_string_literal: true

module Langchain::Tool
  class PaymentGateway < Base
    NAME = "payment_gateway"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    def charge_customer(customer_id:, amount:)
      {success: true, transaction_id: SecureRandom.uuid, amount: amount, customer_id: customer_id, transaction_type: "charge", transaction_date: Time.now}
    end

    def refund_customer(customer_id:, amount:)
      {success: true, transaction_id: SecureRandom.uuid, amount: amount, customer_id: customer_id, transaction_type: "refund", transaction_date: Time.now}
    end
  end
end
