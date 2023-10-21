require "rails/generators/active_record"

module Langchain
  module Generators
    class PgvectorGenerator < Rails::Generators::Base
      desc "TODO: Add description"

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

      def model_name
        options["model"]
      end

      def table_name
        model_name.downcase.pluralize
      end

      def llm
        options["llm"]
      end

      def llm_class
        Langchain::LLM.const_get(LLMS[llm])
      end

      def vector_dimension
        llm_class.default_dimension
      end
    end
  end
end
