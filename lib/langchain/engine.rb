module LangChain
  class Engine < ::Rails::Engine
    isolate_namespace LangChain

    config.autoload_paths << root.join("lib")
    config.eager_load_paths << root.join("lib")

    initializer "LangChain.inflector" do
      Rails.autoloaders.once.inflector.inflect(
        "langchain" => "LangChain"
      )
    end
  end
end
