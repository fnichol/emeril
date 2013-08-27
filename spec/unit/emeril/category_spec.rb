# -*- encoding: utf-8 -*-

require_relative '../../spec_helper'
require 'vcr'

require 'emeril/category'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

describe Emeril::Category do

  describe ".for_cookbook" do
    it "returns a category string for a known cookbook" do
      VCR.use_cassette('known_cookbook') do
        Emeril::Category.for_cookbook('mysql').must_equal 'Databases'
      end
    end

    it "returns nil for a nonexistant cookbook" do
      VCR.use_cassette('nonexistant_cookbook') do
        Emeril::Category.for_cookbook('fooboobunnyyaya').must_be_nil
      end
    end
  end
end
