# -*- encoding: utf-8 -*-

module Emeril

  # A rather insane and questionable class to quickly consume a metadata.rb
  # file and return the cookbook name and version attributes.
  #
  # @see https://twitter.com/fnichol/status/281650077901144064
  # @see https://gist.github.com/4343327
  # @author Fletcher Nichol <fnichol@nichol.ca>
  #
  class MetadataChopper < Hash

    # Creates a new instances and loads in the contents of the metdata.rb
    # file. If you value your life, you may want to avoid reading the
    # implementation.
    #
    # @param metadata_file [String] path to a metadata.rb file
    #
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
end
