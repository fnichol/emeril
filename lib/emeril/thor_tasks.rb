require 'thor'
require 'chef/knife'

require 'emeril'

module Emeril

  # Emeril Rake task generator.
  #
  # @author Fletcher Nichol <fnichol@nichol.ca>
  class ThorTasks < Thor

    namespace :emeril

    # Creates Emeril Thor tasks and allows the callee to configure it.
    #
    # @yield [self] gives itself to the block
    def initialize(*args)
      super
      @logger = Chef::Log
      yield self if block_given?
      define
    end

    private

    attr_accessor :logger

    def define
      metadata = Emeril::MetadataChopper.new("metadata.rb")

      self.class.desc "release",
        "Create git tag for #{metadata[:name]}-#{metadata[:version]}" +
        " and push to the Community Site"
      self.class.send(:define_method, :all) do
        Chef::Knife.new.configure_chef
        Emeril::Releaser.new(:logger => logger).run
      end
    end
  end
end
