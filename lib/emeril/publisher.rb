require 'chef/cookbook_loader'
require 'chef/cookbook_uploader'
require 'chef/cookbook_site_streaming_uploader'
require 'chef/knife/cookbook_site_share'
require 'chef/knife/core/ui'
require 'fileutils'
require 'tmpdir'

require 'emeril/logging'

module Emeril

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
      entries = %w{
        README.* CHANGELOG.* metadata.{json,rb}
        attributes files libraries providers recipes resources templates
      }

      Dir.glob("#{source_path}/{#{entries.join(',')}}")
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
end
