source 'https://rubygems.org'

gemspec

group :test do
  # allow CI to override the version of Chef for matrix testing
  gem 'chef', (ENV['CHEF_VERSION'] || '>= 0.10.10')
end
