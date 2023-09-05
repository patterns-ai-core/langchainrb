# frozen_string_literal: true

module Langchain
  module DependencyHelper
    class LoadError < ::LoadError; end

    class VersionError < ScriptError; end

    # This method requires and loads the given gem, and then checks to see if the version of the gem meets the requirements listed in `langchain.gemspec`
    # This solution was built to avoid auto-loading every single gem in the Gemfile when the developer will mostly likely be only using a few of them.
    #
    # @param gem_name [String] The name of the gem to load
    # @return [Boolean] Whether or not the gem was loaded successfully
    # @raise [LoadError] If the gem is not installed
    # @raise [VersionError] If the gem is installed, but the version does not meet the requirements
    #
    def depends_on(gem_name, req: true)
      gem(gem_name) # require the gem

      return(true) unless defined?(Bundler) # If we're in a non-bundler environment, we're no longer able to determine if we'll meet requirements

      gem_version = Gem.loaded_specs[gem_name].version
      gem_requirement = Bundler.load.dependencies.find { |g| g.name == gem_name }&.requirement

      raise LoadError unless gem_requirement

      unless gem_requirement.satisfied_by?(gem_version)
        raise VersionError, "The #{gem_name} gem is installed, but version #{gem_requirement} is required. You have #{gem_version}."
      end

      lib_name = gem_name if req == true
      lib_name = req if req.is_a?(String)

      require(lib_name) if lib_name

      true
    rescue ::LoadError
      raise LoadError, "Could not load #{gem_name}. Please ensure that the #{gem_name} gem is installed."
    end
  end
end
