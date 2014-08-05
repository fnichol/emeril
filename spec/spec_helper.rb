# -*- encoding: utf-8 -*-

gem "minitest"

if ENV["CODECLIMATE_REPO_TOKEN"]
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
elsif ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.adapters.define "gem" do
    command_name "Specs"

    add_filter ".gem/"
    add_filter "/spec/"

    add_group "Libraries", "/lib/"
  end
  SimpleCov.start "gem"
end

require "fakefs/safe"
require "minitest/autorun"
require "mocha/setup"

# Nasty hack to redefine IO.read in terms of File#read for fakefs
class IO
  def self.read(*args)
    File.open(args[0], "rb") { |f| f.read(args[1]) }
  end
end

require "chef"
require "chef/cookbook_site_streaming_uploader"
class Chef
  class CookbookSiteStreamingUploader
    # Backwards compat
    class MultipartStream
      alias_method :read_original, :read

      def read(how_much = nil)
        read_original(how_much || size)
      end
    end
  end
end

module Emeril

  # Common spec helpers
  module SpecCommon

    def make_cookbook!(opts = {})
      FileUtils.mkdir_p("#{cookbook_path}/recipes")
      remote_dir = File.join(File.dirname(cookbook_path), "remote")

      create_metadata(opts)
      create_recipe
      create_readme

      run_cmd [
        %{git init},
        %{git config user.email "you@example.com"},
        %{git config user.name "Your Name"},
        %{git add .},
        %{git commit -m "Initial"},
        %{git remote add origin #{remote_dir}},
        %{git init --bare #{remote_dir}}
      ].join(" && ")
    end

    def make_client_key!
      file = "#{File.dirname(cookbook_path)}/client_key.pem"
      FileUtils.cp("#{File.dirname(__FILE__)}/fixtures/client_key.pem", file)
      file
    end

    def run_cmd(cmd, opts = {})
      %x{cd #{opts.fetch(:in, cookbook_path)} && #{cmd}}
    end

    private

    def create_metadata(opts)
      File.open("#{cookbook_path}/metadata.rb", "wb") do |f|
        f.write <<-METADATA_RB.gsub(/^ {10}/, "")
          name             "#{opts.fetch(:name, "emeril")}"
          maintainer       "Michael Bluth"
          maintainer_email "michael@bluth.com"
          license          "Apache 2.0"
          description      "Doing stuff!"
          long_description "Doing stuff!"
          version          "#{opts.fetch(:version, "4.1.1")}"
        METADATA_RB
      end
    end

    def create_recipe
      File.open("#{cookbook_path}/recipes/default.rb", "wb") do |f|
        f.write <<-DEFAULT_RB.gsub(/^ {10}/, "")
          directory "/tmp/yeah"

          package "bash"
        DEFAULT_RB
      end
    end

    def create_readme
      File.open("#{cookbook_path}/README.md", "wb") do |f|
        f.write <<-README.gsub(/^ {10}/, "")
          # The beast of the beasts
        README
      end
    end
  end
end
