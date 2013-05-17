# -*- encoding: utf-8 -*-

require 'net/http'
require 'json'

module Emeril

  # A category for a cookbook on the Community Site.
  #
  # @author Fletcher Nichol <fnichol@nichol.ca>
  class Category

    # Returns the category for the given cookbook on the Community Site or
    # nil if it is not present.
    #
    # @param [String] cookbook a cookbook name
    # @return [String,nil] the cookbook category or nil if it is not present
    #   on the Community site
    #
    def self.for_cookbook(cookbook)
      path = "/api/v1/cookbooks/#{cookbook}"
      response = Net::HTTP.get_response("cookbooks.opscode.com", path)
      JSON.parse(response.body)['category']
    end
  end
end
