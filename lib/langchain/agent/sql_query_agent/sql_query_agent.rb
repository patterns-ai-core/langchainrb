module Agent
  class SQLQueryAgent
    # Initializes the Agent
    #
    # @param llm [Symbol] The LLM to use
    # @param llm_api_key [String] The API key for the LLM
    # @param db_connection_string [String] Database connection info
    def initialize(llm:, llm_api_key:, db_connection_string:)
      LLM::Base.validate_llm!(llm: llm)

      @llm = llm
      @llm_api_key = llm_api_key

      @llm_client = LLM.const_get(LLM::Base::LLMS.fetch(llm)).new(api_key: llm_api_key)
      @db = Tool::Database.new(db_connection_string)
      @schema = @db.schema
    end

    def ask(question:)
      prompt = create_prompt_for_sql(question: question)

      # Get the SQL string to execute
      Langchain.logger.info("SQLQueryAgent: Passing the inital prompt to the #{@llm} LLM")
      sql_string = @llm_client.complete(prompt: prompt)

      # Execute the SQL string and collect the results
      Langchain.logger.info("SQLQueryAgent: Passing the SQL to the Database")
      results = @db.execute(sql_string: sql_string)

      # Pass the results and get the LLM to synthesize the answer to the question
      Langchain.logger.info("SQLQueryAgent: Passing the synthesize prompt to the #{@llm} LLM")
      prompt = create_prompt_for_answer(question: question, results: results)
      @llm_client.complete(prompt: prompt)
    end

    private

    # Create the initial prompt to pass to the LLM
    # @param query_str [String] Question to ask
    # @param tools [Array] Tools to use
    # @return [String] Prompt
    def create_prompt_for_sql(question:)
      prompt_template_sql.format(
        dialect: "Postgres SQL",
        schema: @schema,
        question: question
      )
    end

    # Load the PromptTemplate from the JSON file
    # @return [PromptTemplate] PromptTemplate instance
    def prompt_template_sql
      @template ||= Prompt.load_from_path(
        file_path: Langchain.root.join("agent/sql_query_agent/sql_query_agent_sql_prompt.json")
      )
    end

    # Create the second prompt to pass to the LLM
    # @param query_str [String] Question to ask
    # @param tools [Array] Tools to use
    # @return [String] Prompt
    def create_prompt_for_answer(question:, results:)
      prompt_template_answer.format(
        question: question,
        results: results
      )
    end

    # Load the PromptTemplate from the JSON file
    # @return [PromptTemplate] PromptTemplate instance
    def prompt_template_answer
      @template ||= Prompt.load_from_path(
        file_path: Langchain.root.join("agent/sql_query_agent/sql_query_agent_answer_prompt.json")
      )
    end
  end
end