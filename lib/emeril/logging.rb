# -*- encoding: utf-8 -*-

module Emeril

  # A mixin providing log methods that gracefully fail if no logger is present.
  #
  # @author Fletcher Nichol <fnichol@nichol.ca>
  #
  module Logging

    %w[debug info warn error fatal].map(&:to_sym).each do |meth|
      define_method(meth) do |*args|
        logger && logger.public_send(meth, *args)
      end
    end
  end
end
