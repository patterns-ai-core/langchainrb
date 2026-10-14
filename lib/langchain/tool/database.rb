# frozen_string_literal: true

module Langchain::Tool
  #
  # Connects to a SQL database, executes SQL queries, and outputs DB schema for Agents to use
  #
  # Gem requirements:
  #     gem "sequel", "~> 5.87.0"
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
      @requested_tables = tables
      @excluded_tables = exclude_tables
    end

    # Database Tool: Returns a list of tables in the database
    #
    # @return [Langchain::Tool::Response] List of tables in the database
    def list_tables
      tool_response(content: tables)
    end

    # Database Tool: Returns the schema for a list of tables
    #
    # @param tables [Array<String>] The tables to describe.
    # @return [Langchain::Tool::Response] The schema for the tables
    def describe_tables(tables: [])
      return "No tables specified" if tables.empty?

      Langchain.logger.debug("#{self.class} - Describing tables: #{tables}")

      result = tables
        .map do |table|
          describe_table(table)
        end
        .join("\n")

      tool_response(content: result)
    end

    # Database Tool: Returns the database schema
    #
    # @return [Langchain::Tool::Response] Database schema
    def dump_schema
      Langchain.logger.debug("#{self.class} - Dumping schema tables and keys")

      schemas = tables.map do |table|
        describe_table(table)
      end

      tool_response(content: schemas.join("\n"))
    end

    # Database Tool: Executes a SQL query and returns the results
    #
    # @param input [String] SQL query to be executed
    # @return [Langchain::Tool::Response] Results from the SQL query
    def execute(input:)
      Langchain.logger.debug("#{self.class} - Executing \"#{input}\"")

      tool_response(content: db[input].to_a)
    rescue Sequel::DatabaseError => e
      Langchain.logger.error("#{self.class} - #{e.message}")
      tool_response(content: e.message)
    end

    private

    # The tables the tool works with: the requested ones (all if none were given) minus the excluded ones
    #
    # @return [Array<Symbol>] The table names
    def tables
      names = db.tables
      names &= requested_tables.map(&:to_sym) if requested_tables.any?
      names - excluded_tables.map(&:to_sym)
    end

    # Describes a table and its schema
    #
    # @param table [String] The table to describe
    # @return [Langchain::Tool::Response] The schema for the table
    def describe_table(table)
      columns = db.schema(table)
      primary_keys = columns.select { |_name, info| info[:primary_key] == true }.map(&:first)

      definitions = columns.map do |name, info|
        definition = "#{name} #{info[:type]}"
        definition << " PRIMARY KEY" if primary_keys == [name]
        definition << " COMMENT '#{info[:comment]}'" if info[:comment]
        definition
      end
      definitions << "PRIMARY KEY (#{primary_keys.join(",")})" if primary_keys.size > 1
      db.foreign_key_list(table).each do |fk|
        definitions << "FOREIGN KEY (#{fk[:columns]&.first}) REFERENCES #{fk[:table]}(#{fk[:key]&.first})"
      end

      tool_response(content: "CREATE TABLE #{table}(\n#{definitions.join(",\n")});\n")
    end
  end
end
