# frozen_string_literal: true

module Langchain::Tool
  #
  # Connects to a SQL database, executes SQL queries, and outputs DB schema for Agents to use
  #
  # Gem requirements:
  #     gem "sequel", "~> 5.68.0"
  #
  # Usage:
  #     database = Langchain::Tool::Database.new(connection_string: "postgres://user:password@localhost:5432/db_name")
  #
  class Database
    extend Langchain::ToolDefinition
    include Langchain::DependencyHelper

    define_function :list_tables, description: "Database Tool: Returns a list of tables in the database"

    define_function :describe_tables, description: "Database Tool: Returns the schema for a list of tables" do
      property :tables, type: "array", description: "The tables to describe", required: true do
        item type: "string"
      end
    end

    define_function :dump_schema, description: "Database Tool: Returns the database schema"

    define_function :execute, description: "Database Tool: Executes a SQL query and returns the results" do
      property :input, type: "string", description: "SQL query to be executed", required: true
    end

    attr_reader :db, :requested_tables, :excluded_tables

    # Establish a database connection
    #
    # @param connection_string [String] Database connection info, e.g. 'postgres://user:password@localhost:5432/db_name'
    # @param tables [Array<Symbol>] The tables to use. Will use all if empty.
    # @param except_tables [Array<Symbol>] The tables to exclude. Will exclude none if empty.
    # @return [Database] Database object
    def initialize(connection_string:, tables: [], exclude_tables: [])
      depends_on "sequel"

      raise StandardError, "connection_string parameter cannot be blank" if connection_string.empty?

      @db = Sequel.connect(connection_string)
      # TODO: This is a bug, these 2 parameters are completely ignored.
      @requested_tables = tables
      @excluded_tables = exclude_tables
    end

    # Database Tool: Returns a list of tables in the database
    #
    # @return [Array<Symbol>] List of tables in the database
    def list_tables
      db.tables
    end

    # Database Tool: Returns the schema for a list of tables
    #
    # @param tables [Array<String>] The tables to describe.
    # @return [String] The schema for the tables
    def describe_tables(tables: [])
      return "No tables specified" if tables.empty?

      Langchain.logger.debug("#{self.class} - Describing tables: #{tables}")

      tables
        .map do |table|
          describe_table(table)
        end
        .join("\n")
    end

    # Database Tool: Returns the database schema
    #
    # @return [String] Database schema
    def dump_schema
      Langchain.logger.debug("#{self.class} - Dumping schema tables and keys")

      schemas = db.tables.map do |table|
        describe_table(table)
      end
      schemas.join("\n")
    end

    # Database Tool: Executes a SQL query and returns the results
    #
    # @param input [String] SQL query to be executed
    # @return [Array] Results from the SQL query
    def execute(input:)
      Langchain.logger.debug("#{self.class} - Executing \"#{input}\"")

      db[input].to_a
    rescue Sequel::DatabaseError => e
      Langchain.logger.error("#{self.class} - #{e.message}")
      e.message # Return error to LLM
    end

    private

    # Describes a table and its schema
    #
    # @param table [String] The table to describe
    # @return [String] The schema for the table
    def describe_table(table)
      # TODO: There's probably a clear way to do all of this below

      primary_key_columns = []
      primary_key_column_count = db.schema(table).count { |column| column[1][:primary_key] == true }

      schema = "CREATE TABLE #{table}(\n"
      db.schema(table).each do |column|
        schema << "#{column[0]} #{column[1][:type]}"
        if column[1][:primary_key] == true
          schema << " PRIMARY KEY" if primary_key_column_count == 1
        else
          primary_key_columns << column[0]
        end
        schema << ",\n" unless column == db.schema(table).last && primary_key_column_count == 1
      end
      if primary_key_column_count > 1
        schema << "PRIMARY KEY (#{primary_key_columns.join(",")})"
      end
      db.foreign_key_list(table).each do |fk|
        schema << ",\n" if fk == db.foreign_key_list(table).first
        schema << "FOREIGN KEY (#{fk[:columns]&.first}) REFERENCES #{fk[:table]}(#{fk[:key]&.first})"
        schema << ",\n" unless fk == db.foreign_key_list(table).last
      end
      schema << ");\n"
    end
  end
end
