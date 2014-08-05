# -*- encoding: utf-8 -*-

require "English"

require 'emeril/logging'

module Emeril

  # Exception class raised when a git repo is not clean.
  #
  class GitNotCleanError < StandardError ; end

  # Exception class raised when a git push does not return successfully.
  #
  class GitPushError < StandardError ; end

  # Applies a version tag on a git repository and pushes it to the origin
  # remote.
  #
  # @author Fletcher Nichol <fnichol@nichol.ca>
  #
  class GitTagger

    include Logging

    # Creates a new instance.
    #
    # @param [Hash] options configuration for a git tagger
    # @option options [Logger] an optional logger instance
    # @option options [String] source_path the path to a git repository
    # @option options [String] tag_prefix a prefix for a git tag version string
    # @option options [String] version (required) a version string
    # @raise [ArgumentError] if any required options are not set
    #
    def initialize(options = {})
      @logger = options[:logger]
      @source_path = options.fetch(:source_path, Dir.pwd)
      @tag_prefix = case options[:tag_prefix]
      when nil then
        DEFAULT_TAG_PREFIX
      when false
        ""
      else
        options[:tag_prefix]
      end
      @version = options.fetch(:version) do
        raise ArgumentError, ":version must be set"
      end
    end

    # Applies a version tag on a git repository and pushes it to the origin
    # remote.
    #
    def run
      guard_clean
      tag_version { git_push } unless already_tagged?
    end

    private

    DEFAULT_TAG_PREFIX = "v".freeze

    attr_reader :logger, :source_path, :tag_prefix, :version

    def already_tagged?
      if sh_with_code('git tag')[0].split(/\n/).include?(version_tag)
        info("Tag #{version_tag} has already been created.")
        true
      end
    end

    def clean?
      sh_with_code("git status --porcelain")[0].empty?
    end

    def git_push
      perform_git_push
      perform_git_push ' --tags'
      info("Pushed git commits and tags.")
    end

    def guard_clean
      if !clean?
        raise GitNotCleanError,
          "There are files that need to be committed first."
      end
    end

    def perform_git_push(options = '')
      cmd = "git push origin master #{options}"
      out, code = sh_with_code(cmd)
      if code != 0
        raise GitPushError,
          "Couldn't git push. `#{cmd}' failed with the following output:" \
            "\n\n#{out}\n"
      end
    end

    def sh_with_code(cmd, &block)
      cmd << " 2>&1"
      outbuf = ''
      debug(cmd)
      Dir.chdir(source_path) {
        outbuf = `#{cmd}`
        if $CHILD_STATUS == 0
          block.call(outbuf) if block
        end
      }
      [outbuf, $CHILD_STATUS]
    end

    def tag_version
      sh_with_code(%{git tag -a -m \"Version #{version}\" #{version_tag}})
      info("Tagged #{version_tag}.")
      yield if block_given?
    rescue
      error("Untagging #{version_tag} due to error.")
      sh_with_code("git tag -d #{version_tag}")
      raise
    end

    def version_tag
      "#{tag_prefix}#{version}"
    end
  end
end
