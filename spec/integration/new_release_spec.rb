# -*- encoding: utf-8 -*-

require_relative '../spec_helper'
require 'vcr'

require 'chef/knife'
require 'emeril'

VCR.configure do |config|
  config.ignore_hosts "codeclimate.com"
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock

  # remove sensitive authentication information from the recording
  config.before_record do |interaction|
    headers = interaction.request.headers
    headers.keys.
      select { |k| k =~ /^X-Ops-(Authorization-|Content-Hash)/ }.
      each { |header| headers[header] = Array("{{#{header}}}") }
    headers["X-Ops-Userid"] = "opsycodesy"
  end
end

describe "Releasing and publishing a cookbook" do

  include Emeril::SpecCommon

  before do
    @saved = Hash.new
    %w[node_name client_key].map(&:to_sym).each do |attr|
      @saved[attr] = Chef::Config[attr]
    end

    Chef::Config[:node_name] = ENV["CHEF_NODE_NAME"] || "opsycodesy"
    Chef::Config[:client_key] = ENV["CHEF_CLIENT_KEY"] || make_client_key!
  end

  after do
    %w[node_name client_key].map(&:to_sym).each do |attr|
      Chef::Config[attr] = @saved.delete(attr)
    end

    FileUtils.remove_dir(cookbook_path)
  end

  let(:cookbook_path) { File.join(Dir.mktmpdir, "emeril") }

  let(:logger) do
    if ENV["DEBUG"]
      Chef::Log.level = Logger::DEBUG
      l = Logger.new(STDOUT)
      l.level = Logger::DEBUG
      l
    else
      Logger.new(StringIO.new)
    end
  end

  it "releases a new cookbook" do
    make_cookbook!(:version => "1.2.3")

    VCR.use_cassette('new_release') do
      Emeril::Releaser.new(:logger => logger, :source_path => cookbook_path).run
    end

    # tag was pushed to the remote
    git_tag = run_cmd("git tag", :in => "#{File.dirname(cookbook_path)}/remote")
    git_tag.chomp.must_equal "v1.2.3"
  end
end
