module Langchain::Tool
  class Database < Base
    #
    # Connects to a database, executes SQL queries, and outputs DB schema for Agents to use
    #
    # Gem requirements: gem "sequel", "~> 5.68.0"
    #
    const_set(:NAME, "database")
    description <<~DESC
      Useful for getting the result of a database query.

      The input to this tool should be valid SQL.
    DESC

    # Establish a database connection
    # @param db_connection_string [String] Database connection info, e.g. 'postgres://user:password@localhost:5432/db_name'
    def initialize(db_connection_string)
      depends_on "sequel"
      require "sequel"
      require "sequel/extensions/schema_dumper"

      raise StandardError, "db_connection_string parameter cannot be blank" if db_connection_string.empty?

      @db = Sequel.connect(db_connection_string)
      @db.extension :schema_dumper
    end

    def schema
      Langchain.logger.info("[#{self.class.name}]".light_blue + ": Dumping schema")
      @db.dump_schema_migration(same_db: true, indexes: false) unless @db.adapter_scheme == :mock
    end

    # Evaluates a sql expression
    # @param input [String] sql expression
    # @return [Array] results
    def execute(input:)
      Langchain.logger.info("[#{self.class.name}]".light_blue + ": Executing \"#{input}\"")
      begin
        @db[input].to_a
      rescue Sequel::DatabaseError => e
        Langchain.logger.error("[#{self.class.name}]".light_red + ": #{e.message}")
      end
    end
  end
end
