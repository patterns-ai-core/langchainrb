# frozen_string_literal: true

module Langchain::Tool
  class Database < Base
    description <<~DESC
      Useful for getting the result of a database query.

      The input to this tool should be valid SQL.
    DESC

    def initialize(db_connection_string)
      depends_on "sequel"
      require "sequel"
    end

    def schema
      "the_schema_string"
    end

    # Evaluates a sql expression
    # @param input [String] sql expression
    # @return [String] results
    def execute(sql_string:)
      Langchain.logger.info("Database: Using the Database Tool with \"#{sql_string}\"")
      # Sequel::DB.exec(input)
      "Foo, Bar"
    end
  end
end
