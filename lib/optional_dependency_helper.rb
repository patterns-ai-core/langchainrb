# frozen_string_literal: true

def depends_on(gem_name)
  gem(gem_name) # require the gem

  return(true) unless defined?(Bundler) # If we're in a non-bundler environment, we're no longer able to determine if we'll meet requirements

  gem_version = Gem.loaded_specs[gem_name].version
  gem_requirement = Bundler.load.dependencies.find { |g| g.name == gem_name }.requirement

  if !gem_requirement.satisfied_by?(gem_version)
    raise "The #{gem_name} gem is installed, but version #{gem_requirement} is required. You have #{gem_version}."
  end

  true
rescue LoadError
  raise LoadError, "Could not load #{gem_name}. Please ensure that the #{gem_name} gem is installed."
end
