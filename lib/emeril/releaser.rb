module Emeril

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
      Category.for_cookbook(metadata[:name]) || "Other"
    end
  end
end
