module Langchain
  class Engine < ::Rails::Engine
    isolate_namespace Langchain

    config.autoload_paths << root.join("lib")
    config.eager_load_paths << root.join("lib")
  end
end
