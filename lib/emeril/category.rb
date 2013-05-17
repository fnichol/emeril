require 'net/http'
require 'json'

module Emeril

  class Category

    def self.for_cookbook(cookbook)
      path = "/api/v1/cookbooks/#{cookbook}"
      response = Net::HTTP.get_response("cookbooks.opscode.com", path)
      JSON.parse(response.body)['category']
    end
  end
end
