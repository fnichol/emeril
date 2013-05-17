# -*- encoding: utf-8 -*-

gem 'minitest'

if ENV['SIMPLECOV']
  require 'simplecov'
  SimpleCov.adapters.define 'gem' do
    command_name 'Specs'

    add_filter '.gem/'
    add_filter '/spec/'

    add_group 'Libraries', '/lib/'
  end
  SimpleCov.start 'gem'
end

require 'fakefs/safe'
require 'minitest/autorun'
require 'mocha/setup'

# Nasty hack to redefine IO.read in terms of File#read for fakefs
class IO
  def self.read(*args)
    File.open(args[0], "rb") { |f| f.read(args[1]) }
  end
end
