require "rails/generators/active_record"

module Langchain
  module Generators
    #
    # Usage:
    #     rails g langchain:pgvector -model=Product -llm=openai
    #
    class PgvectorGenerator < Rails::Generators::Base
      desc "This generator adds Pgvector vectorsearch integration to your ActiveRecord model"

      include ::ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      class_option :model, type: :string, required: true, desc: "ActiveRecord Model to add vectorsearch to", aliases: "-m"
      class_option :llm, type: :string, required: true, desc: "LLM provider that will be used to generate embeddings and completions"

      LLMS = {
        "cohere" => "Langchain::LLM::Cohere",
        "google_palm" => "Langchain::LLM::GooglePalm",
        "hugging_face" => "Langchain::LLM::HuggingFace",
        "llama_cpp" => "Langchain::LLM::LlamaCpp",
        "ollama" => "Langchain::LLM::Ollama",
        "openai" => "Langchain::LLM::OpenAI",
        "replicate" => "Langchain::LLM::Replicate"
      }

      def copy_migration
        migration_template "enable_vector_extension_template.rb", "db/migrate/enable_vector_extension.rb", migration_version: migration_version
        migration_template "add_vector_column_template.rb", "db/migrate/add_vector_column_to_#{table_name}.rb", migration_version: migration_version
      end

      def create_initializer_file
        template "initializer.rb", "config/initializers/langchain.rb"
      end

      def migration_version
        "[#{::ActiveRecord::VERSION::MAJOR}.#{::ActiveRecord::VERSION::MINOR}]"
      end

      def add_to_model
        inject_into_class "app/models/#{model_name.downcase}.rb", model_name do
          "  vectorsearch\n\n  after_save :upsert_to_vectorsearch\n\n"
        end
      end

      private

      # @return [String] Name of the model
      def model_name
        options["model"]
      end

      # @return [String] Table name of the model
      def table_name
        model_name.downcase.pluralize
      end

      # @return [String] LLM provider to use
      def llm
        options["llm"]
      end

      # @return [Langchain::LLM::*] LLM class
      def llm_class
        Langchain::LLM.const_get(LLMS[llm])
      end

      # @return [Integer] Dimension of the vector to be used
      def vector_dimension
        llm_class.default_dimension
      end
    end
  end
end
