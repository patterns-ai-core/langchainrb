# frozen_string_literal: true

RSpec.describe "depends_on" do
  subject do
    object = Object.new
    object.extend(Langchain::DependencyHelper)
    object
  end

  it "doesn't raise an error if the gem is included" do
    expect { subject.depends_on("rspec") }.not_to raise_error
  end

  it "raises an error if the gem isn't included" do
    expect { subject.depends_on("random-gem") }.to raise_error(Langchain::DependencyHelper::LoadError, /Could not load random-gem/)
  end

  it "raises an error when it doesn't have it as a bundler dependency" do
    bundler_load = double(:load, dependencies: [])
    allow(Bundler).to receive(:load).and_return(bundler_load)

    expect { subject.depends_on("rspec") }.to raise_error(Langchain::DependencyHelper::LoadError, /Could not load rspec/)
  end

  it "raises an error when it doesn't match gem version requirement" do
    gem_loaded_spec = double(:specs, "[]": double(:version, version: Gem::Version.new("0.1")))
    allow(Gem).to receive(:loaded_specs).and_return(gem_loaded_spec)

    expect { subject.depends_on("rspec") }.to raise_error(Langchain::DependencyHelper::VersionError, /The rspec gem is installed.*You have 0.1/)
  end
end
