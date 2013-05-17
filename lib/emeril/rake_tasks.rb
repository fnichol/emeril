require 'rake/tasklib'
require 'chef/knife'

require 'emeril'

module Emeril

  # Emeril Rake task generator.
  #
  # @author Fletcher Nichol <fnichol@nichol.ca>
  class RakeTasks < ::Rake::TaskLib

    # Creates Emeril Rake tasks and allows the callee to configure it.
    #
    # @yield [self] gives itself to the block
    def initialize
      @logger = Chef::Log
      yield self if block_given?
      define
    end

    private

    attr_accessor :logger

    def define
      metadata = Emeril::MetadataChopper.new("metadata.rb")

      desc "Create git tag for #{metadata[:name]}-#{metadata[:version]}" +
        " and push to the Community Site"
      task "release" do
        Chef::Knife.new.configure_chef
        Emeril::Releaser.new(:logger => logger).run
      end
    end
  end
end
