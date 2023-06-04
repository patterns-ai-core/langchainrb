# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"
require "yard"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

Rake::Task["spec"].enhance do
  Rake::Task["standard:fix"].invoke
end

YARD::Rake::YardocTask.new do |t|
  t.options = ["--fail-on-warning"]
end
