# -*- encoding: utf-8 -*-

require "net/https"
require "json"
require "uri"

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
      uri = URI("https://supermarket.getchef.com/api/v1/cookbooks/#{cookbook}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      JSON.parse(response.body)["category"]
    end
  end
end
