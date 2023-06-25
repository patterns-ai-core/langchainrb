# frozen_string_literal: true

module Langchain
  class Railtie < Rails::Railtie
    initializer "langchain" do
      ActiveSupport.on_load(:active_record) do
        ::ActiveRecord::Base.include Langchain::ActiveRecord::Hooks
      end
    end
  end
end
