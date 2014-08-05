ignore %r{^\.gem/}

group :red_green_refactor, halt_on_fail: true do
  guard :minitest do
    watch(%r|^spec/(.*)_spec\.rb|)
    watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "spec/unit/#{m[1]}#{m[2]}_spec.rb" }
    watch(%r|^spec/spec_helper\.rb|)    { "spec" }
  end

  guard :cane do
    watch(%r|.*\.rb|)
    watch('.cane')
  end

  guard :rubocop, all_on_start: false, keep_failed: false, cli: "-r finstyle" do
    watch(%r{.+\.rb$})
    watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
  end
end

guard :yard, port: "8808" do
  watch(%r{lib/.+\.rb})
end
