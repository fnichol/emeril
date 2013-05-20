# -*- encoding: utf-8 -*-

require 'emeril/category'
require 'emeril/git_tagger'
require 'emeril/metadata_chopper'
require 'emeril/publisher'

module Emeril

  # Tags a git commit with a version string and pushes the cookbook to the
  # Community Site.
  #
  # @author Fletcher Nichol <fnichol@nichol.ca>
  #
  class Releaser

    # Creates a new instance.
    #
    # @param [Hash] options configuration for a releaser
    # @option options [Logger] an optional logger instance
    # @option options [String] source_path the path to a git repository
    # @option options [Hash] metadata a hash of cookbook metadata
    # @option options [String] category a Community Site category for the
    #   cookbook
    # @option options [GitTagger] git_tagger a git tagger
    # @option options [Publisher] publisher a publisher
    # @raise [ArgumentError] if any required options are not set
    #
    def initialize(options = {})
      @logger = options[:logger]
      @tag_prefix = options[:tag_prefix]
      @source_path = options.fetch(:source_path, Dir.pwd)
      @metadata = options.fetch(:metadata) { default_metadata }
      @category = options.fetch(:category) { default_category }
      @git_tagger = options.fetch(:git_tagger) { default_git_tagger }
      @publisher = options.fetch(:publisher) { default_publisher }
    end

    # Tags and releases a cookbook.
    #
    def run
      git_tagger.run
      publisher.run
    end

    private

    DEFAULT_CATEGORY = "Other".freeze

    attr_reader :logger, :tag_prefix, :source_path, :metadata,
      :category, :git_tagger, :publisher

    def default_metadata
      metadata_file = File.expand_path(File.join(source_path, "metadata.rb"))
      MetadataChopper.new(metadata_file)
    end

    def default_git_tagger
      GitTagger.new(
        :logger => logger,
        :source_path => source_path,
        :version => metadata[:version],
        :tag_prefix => tag_prefix
      )
    end

    def default_publisher
      Publisher.new(
        :logger => logger,
        :source_path => source_path,
        :name => metadata[:name],
        :category => category
      )
    end

    def default_category
      Category.for_cookbook(metadata[:name]) || "Other"
    end
  end
end
