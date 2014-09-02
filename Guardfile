# -*- encoding: utf-8 -*-
ignore %r{^\.gem/}

def minitest_opts
  {}
end

def cane_opts
  {}
end

def rubocop_opts
  { :all_on_start => false, :keep_failed => false, :cli => "-r finstyle -D" }
end

def yard_opts
  { :port => 8808 }
end

group :red_green_refactor, :halt_on_fail => true do
  guard :minitest, minitest_opts do
    watch(%r{^spec/(.*)_spec\.rb})
    watch(%r{^lib/(.*)([^/]+)\.rb})   { |m| "spec/unit/#{m[1]}#{m[2]}_spec.rb" }
    watch(%r{^spec/spec_helper\.rb})  { "spec" }
  end

  guard :cane, cane_opts do
    watch(%r{.*\.rb})
    watch(".cane")
  end

  guard :rubocop, rubocop_opts do
    watch(%r{.+\.rb$})
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end

guard :yard, yard_opts do
  watch(%r{lib/.+\.rb})
end
