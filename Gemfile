# -*- encoding: utf-8 -*-
source "https://rubygems.org"

gemspec

group :guard do
  gem "guard-minitest"
  gem "guard-rubocop"
  gem "guard-cane"
  gem "guard-yard"
end

group :test do
  # allow CI to override the version of Chef for matrix testing
  gem "chef", (ENV["CHEF_VERSION"] || ">= 0.10.10")

  gem "codeclimate-test-reporter", :require => nil
end
