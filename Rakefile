require "bundler/gem_tasks"
require "rake/testtask"
require "cane/rake_task"

Rake::TestTask.new(:unit) do |t|
  t.libs.push "lib"
  t.test_files = FileList["spec/unit/**/*_spec.rb"]
  t.verbose = true
end

Rake::TestTask.new(:integration) do |t|
  t.libs.push "lib"
  t.test_files = FileList["spec/integration/**/*_spec.rb"]
  t.verbose = true
end

desc "Run all test suites"
task :test => [:unit, :integration]

require "finstyle"
require "rubocop/rake_task"
RuboCop::RakeTask.new(:style) do |task|
  task.options << "--display-cop-names"
end

desc "Run cane to check quality metrics"
Cane::RakeTask.new do |cane|
  cane.canefile = "./.cane"
end

desc "Display LOC stats"
task :stats do
  puts "\n## Production Code Stats"
  sh "countloc -r lib"
  puts "\n## Test Code Stats"
  sh "countloc -r spec"
end

desc "Run all quality tasks"
task :quality => [:cane, :style, :stats]

task :default => [:test, :quality]
