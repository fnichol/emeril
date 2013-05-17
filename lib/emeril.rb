require 'logger'
require 'tmpdir'
require 'fileutils'
require 'net/http'
require 'json'
require 'chef/knife/cookbook_site_share'
require 'chef/cookbook_loader'
require 'chef/cookbook_uploader'
require 'chef/cookbook_site_streaming_uploader'

require "emeril/version"

module Emeril

  module Logging

    %w{debug info warn error fatal}.map(&:to_sym).each do |meth|
      define_method(meth) do |*args|
        logger && logger.public_send(meth, *args)
      end
    end
  end

  class MetadataChopper < Hash

    def initialize(metadata_file)
      eval(IO.read(metadata_file), nil, metadata_file)
      %w{name version}.map(&:to_sym).each do |attr|
        if self[:name].nil?
          raise "Missing attribute `#{attr}' must be set in #{metadata_file}"
        end
      end
    end

    def method_missing(meth, *args, &block)
      self[meth] = args.first
    end
  end

  class GitTagger

    include Logging

    def initialize(options = {})
      @logger = options[:logger]
      @source_path = options.fetch(:source_path, Dir.pwd)
      @tag_prefix = options.fetch(:tag_prefix, DEFAULT_TAG_PREFIX)
      @version = options.fetch(:version) do
        raise ArgumentError, ":version must be set"
      end
    end

    def run
      guard_clean
      tag_version { git_push } unless already_tagged?
    end

    private

    DEFAULT_TAG_PREFIX = "v".freeze

    attr_reader :logger, :source_path, :tag_prefix, :version

    def already_tagged?
      if sh('git tag').split(/\n/).include?(version_tag)
        info("Tag #{version_tag} has already been created.")
        true
      end
    end

    def clean?
      sh_with_code("git diff --exit-code")[1] == 0
    end

    def git_push
      perform_git_push
      perform_git_push ' --tags'
      info("Pushed git commits and tags.")
    end

    def guard_clean
      clean? or raise("There are files that need to be committed first.")
    end

    def perform_git_push(options = '')
      cmd = "git push #{options}"
      out, code = sh_with_code(cmd)
      if code != 0
        raise "Couldn't git push. `#{cmd}' failed with the following output:" +
          "\n\n#{out}\n"
      end
    end

    def sh(cmd, &block)
      out, code = sh_with_code(cmd, &block)
      if code == 0
        out
      elsif out.empty?
        raise "Running `#{cmd}' failed." +
          " Run this command directly for more detailed output."
      else
        raise out
      end
    end

    def sh_with_code(cmd, &block)
      cmd << " 2>&1"
      outbuf = ''
      debug(cmd)
      Dir.chdir(source_path) {
        outbuf = `#{cmd}`
        if $? == 0
          block.call(outbuf) if block
        end
      }
      [outbuf, $?]
    end

    def tag_version
      sh "git tag -a -m \"Version #{version}\" #{version_tag}"
      info "Tagged #{version_tag}."
      yield if block_given?
    rescue
      error "Untagging #{version_tag} due to error."
      sh_with_code "git tag -d #{version_tag}"
      raise
    end

    def version_tag
      "#{tag_prefix}#{version}"
    end
  end

  class Publisher

    include Logging

    def initialize(options = {})
      @logger = options[:logger]
      @source_path = options.fetch(:source_path, Dir.pwd)
      @name = options.fetch(:name) { raise ArgumentError, ":name must be set" }
      @category = options[:category]
      validate_chef_config!
    end

    def run
      sandbox_path = sandbox_cookbook
      share = SharePlugin.new
      share.ui = logging_ui(share.ui)
      share.config[:cookbook_path] = sandbox_path
      share.name_args = [name, category]
      share.run
    ensure
      FileUtils.remove_dir(sandbox_path)
    end

    private

    attr_reader :logger, :source_path, :name, :category

    def validate_chef_config!
      %w{node_name client_key}.map(&:to_sym).each do |attr|
        raise "Chef::Config[:#{attr}] must be set" if ::Chef::Config[attr].nil?
      end
    end

    def sandbox_cookbook
      path = Dir.mktmpdir
      target = File.join(path, name)
      debug("Creating cookbook sanbox directory at #{target}")
      FileUtils.mkdir_p(target)
      FileUtils.cp_r(cookbook_files, target)
      path
    end

    def cookbook_files
      ruby_dirs = %w{
        attributes files libraries providers recipes resources templates
      }.join(",")
      docs = %w{README.* CHANGELOG.*}.join(",")

      Dir.glob("#{source_path}/{metadata.{json,rb},#{docs},#{ruby_dirs}}")
    end

    def logging_ui(ui)
      LoggingUI.new(ui.stdout, ui.stderr, ui.stdin, ui.config, logger)
    end

    class LoggingUI < :: Chef::Knife::UI

      def initialize(stdout, stderr, stdin, config, logger)
        super(stdout, stderr, stdin, config)
        @logger = logger
      end

      def msg(message)
        logger ? logger.info(message) : super
      end

      def err(message)
        logger ? logger.error(message) : super
      end

      def warn(message)
        logger ? logger.warn(message) : super
      end

      def fatal(message)
        logger ? logger.fatal(message) : super
      end

      private

      attr_reader :logger
    end

    class SharePlugin < ::Chef::Knife::CookbookSiteShare

      def exit(code)
        raise "Knife Plugin exited with error code: #{code}"
      end
    end
  end

  class Category

    def self.for(cookbook)
      path = "/api/v1/cookbooks/#{cookbook}"
      response = Net::HTTP.get_response("cookbooks.opscode.com", path)
      JSON.parse(response.body)['category']
    end
  end

  class Releaser

    def initialize(options = {})
      @logger = options[:logger]
      @source_path = options.fetch(:source_path, Dir.pwd)
      @metadata = options.fetch(:metadata) { default_metadata }
      @category = options.fetch(:category) { default_category }
      @git_tagger = options.fetch(:git_tagger) { default_git_tagger }
      @publisher = options.fetch(:publisher) { default_publisher }
    end

    def run
      git_tagger.run
      publisher.run
    end

    private

    DEFAULT_CATEGORY = "Other".freeze

    attr_reader :logger, :source_path, :metadata,
      :category, :git_tagger, :publisher

    def default_metadata
      metadata_file = File.expand_path(File.join(source_path, "metadata.rb"))
      MetadataChopper.new(metadata_file)
    end

    def default_git_tagger
      GitTagger.new(
        :logger => logger,
        :source_path => source_path,
        :version => metadata[:version]
      )
    end

    def default_publisher
      Publisher.new(
        :logger => logger,
        :source_path => source_path,
        :source_path => source_path,
        :name => metadata[:name],
        :category => category
      )
    end

    def default_category
      Category.for(metadata[:name]) || "Other"
    end
  end
end
