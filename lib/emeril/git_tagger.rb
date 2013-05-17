require 'emeril/logging'

module Emeril

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
end
