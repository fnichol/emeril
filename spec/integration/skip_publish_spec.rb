# -*- encoding: utf-8 -*-

require_relative "../spec_helper"
require "vcr"

require "chef/knife"
require "emeril"

VCR.configure do |config|
  config.ignore_hosts "codeclimate.com"
end

describe "Releasing and but not publishing a cookbook" do

  include Emeril::SpecCommon

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
    make_cookbook!(:version => "4.5.6")

    VCR.use_cassette("new_release") do
      Emeril::Releaser.new(
        :logger                 => logger,
        :source_path            => cookbook_path,
        :publish_to_supermarket => false
      ).run
    end

    # tag was pushed to the remote
    git_tag = run_cmd("git tag", :in => "#{File.dirname(cookbook_path)}/remote")
    git_tag.chomp.must_equal "v4.5.6"
  end

  it "releases a new cookbook with a custom git tag prefix" do
    make_cookbook!(:version => "1.0.0")

    VCR.use_cassette("new_release") do
      Emeril::Releaser.new(
        :logger                 => logger,
        :source_path            => cookbook_path,
        :publish_to_supermarket => false,
        :tag_prefix             => "release-"
      ).run
    end

    # tag was pushed to the remote
    git_tag = run_cmd("git tag", :in => "#{File.dirname(cookbook_path)}/remote")
    git_tag.chomp.must_equal "release-1.0.0"
  end
end
