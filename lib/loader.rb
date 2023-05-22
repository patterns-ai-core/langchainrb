module Loader
  def self.with(*loaders)
    LoaderSet.new(loaders)
  end

  class LoaderSet
    def initialize(loaders)
      @loaders = Array(loaders)
    end

    def load(*paths)
      Array(paths)
        .flatten
        .map { |path| first_loadable_loader(path)&.load } # TODO: first_loadable_loader(path)&.load_chunked
        .compact
    end

    def first_loadable_loader(path)
      @loaders
        .each do |loader_klass|
          loader_instance = loader_klass.new(path)
          return(loader_instance) if loader_instance.loadable?
        end
    end
  end
end
