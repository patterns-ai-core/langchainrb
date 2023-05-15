# frozen_string_literal: true

def require_optional_dependency(name)
  gem name # require the gem

  gem_version = Gem.loaded_specs[name].version
  gem_requirement = Bundler.load.dependencies.find { |g| g.name == name }.requirement

  if !gem_requirement.satisfied_by?(gem_version)
    raise "The #{name} gem is installed, but version #{gem_requirement} is required. You have #{gem_version}."
  end
rescue LoadError
  raise LoadError, "Could not load #{name}. Please ensure that the #{name} gem is installed."
end
