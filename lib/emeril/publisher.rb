# -*- encoding: utf-8 -*-

require 'chef/cookbook_uploader'
require 'chef/cookbook_loader'
require 'chef/cookbook_site_streaming_uploader'
require 'chef/knife/cookbook_site_share'
require 'chef/knife/core/ui'
require 'chef/mixin/command'
require 'fileutils'
require 'tmpdir'

require 'emeril/logging'

module Emeril

  # Takes a path to a cookbook and pushes it up to the Community Site.
  #
  # @author Fletcher Nichol <fnichol@nichol.ca>
  #
  class Publisher

    include Logging

    # Creates a new instance.
    #
    # @param [Hash] options configuration for a publisher
    # @option options [Logger] an optional logger instance
    # @option options [String] source_path the path to a git repository
    # @option options [String] name (required) the name of the cookbook
    # @option options [String] category a Community Site category for the
    #   cookbook
    # @option options [Chef::Knife] knife_class an alternate Knife plugin class
    #   to create, configure, and invoke
    # @raise [ArgumentError] if any required options are not set
    #
    def initialize(options = {})
      @logger = options[:logger]
      @source_path = options.fetch(:source_path, Dir.pwd)
      @name = options.fetch(:name) { raise ArgumentError, ":name must be set" }
      @category = options[:category]
      @knife_class = options.fetch(:knife_class, SharePlugin)
      validate_chef_config!
    end

    # Prepares a sandbox copy of the cookbook and uploads it to the Community
    # Site.
    #
    def run
      sandbox_path = sandbox_cookbook
      share = knife_class.new
      share.ui = logging_ui(share.ui)
      share.config[:cookbook_path] = sandbox_path
      share.name_args = [name, category]
      share.run
    ensure
      FileUtils.remove_dir(sandbox_path)
    end

    protected

    attr_reader :logger, :source_path, :name, :category, :knife_class

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
      entries = %w{
        README.* CHANGELOG.* metadata.{json,rb} attributes definitions
        files libraries providers recipes resources templates
      }

      Dir.glob("#{source_path}/{#{entries.join(',')}}")
    end

    def logging_ui(ui)
      LoggingUI.new(ui.stdout, ui.stderr, ui.stdin, ui.config, logger)
    end

    # A custom knife UI that sends logging methods to a logger, if it exists.
    #
    class LoggingUI < :: Chef::Knife::UI

      def initialize(stdout, stderr, stdin, config, logger)
        super(stdout, stderr, stdin, config)
        @logger = logger
      end

      def msg(message)
        logger ? logger.info(message) : super
      end
      alias_method :info, :msg

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

    # A custom cookbook site share knife plugin that intercepts Kernel#exit
    # calls and converts them to an exception raise.
    #
    class SharePlugin < ::Chef::Knife::CookbookSiteShare

      def exit(code)
        raise "Knife Plugin exited with error code: #{code}"
      end
    end
  end
end
