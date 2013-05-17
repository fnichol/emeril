module Emeril

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
end
