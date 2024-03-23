# frozen_string_literal: true

module Langchain::Tool
  class InventoryManagement < Base
    NAME = "inventory_management"
    ANNOTATIONS_PATH = Langchain.root.join("./langchain/tool/#{NAME}/#{NAME}.json").to_path

    attr_accessor :inventory

    def initialize
      @inventory = {
        "A3045809" => 10,
        "B9384509" => 5,
        "Z0394853" => 2,
        "X3048509" => 3,
        "Y3048509" => 1,
        "L3048509" => 0
      }
    end

    def check_inventory(sku:, quantity:)
      @inventory.fetch(sku, 0) >= quantity
    end

    def update_inventory(sku:, quantity:)
      @inventory[sku] = quantity
    end
  end
end
