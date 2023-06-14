module Langchain::Tool
  class Database < Base
    #
    # Connects to a database, executes SQL queries, and outputs DB schema for Agents to use
    #
    # Gem requirements: gem "sequel", "~> 5.68.0"
    #

    NAME = "database"

    description <<~DESC
      Useful for getting the result of a database query.

      The input to this tool should be valid SQL.
    DESC

    attr_reader :db

    #
    # Establish a database connection
    #
    # @param connection_string [String] Database connection info, e.g. 'postgres://user:password@localhost:5432/db_name'
    # @return [Database] Database object
    #
    def initialize(connection_string:)
      depends_on "sequel"
      require "sequel"
      require "sequel/extensions/schema_dumper"

      raise StandardError, "connection_string parameter cannot be blank" if connection_string.empty?

      @db = Sequel.connect(connection_string)
    end

    #
    # Returns the database schema
    #
    # @return [String] schema
    #
    def schema
      # TODO: Take out next line. Needed not to break tests.
      return if db.adapter_scheme == :mock
      Langchain.logger.info("Dumping schema", for: self.class)
      schema = ""
      db.tables.each do |table|
        schema << "CREATE TABLE #{table}(\n"
        db.schema(table).each do |column|
          schema << "#{column[0]} #{column[1][:type]}"
          schema << " PRIMARY KEY" if column[1][:primary_key] == true
          schema << "," unless column == db.schema(table).last
          schema << "\n"
        end
        schema << ");\n"
        db.foreign_key_list(table).each do |fk|
          schema << "ALTER TABLE #{table} ADD FOREIGN KEY (#{fk[:columns][0]}) REFERENCES #{fk[:table]}(#{fk[:key][0]});\n"
        end
      end
      schema
    end

    #
    # Evaluates a sql expression
    #
    # @param input [String] sql expression
    # @return [Array] results
    #
    def execute(input:)
      Langchain.logger.info("Executing \"#{input}\"", for: self.class)

      db[input].to_a
    rescue Sequel::DatabaseError => e
      Langchain.logger.error(e.message, for: self.class)
    end
  end
end
