# -*- encoding: utf-8 -*-

require_relative "../../spec_helper"

require "emeril/metadata_chopper"

describe Emeril::MetadataChopper do

  before do
    FakeFS.activate!
    FileUtils.mkdir_p("/tmp")
  end

  after do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  it "contains a :name attribute" do
    stub_metadata!("banzai")
    Emeril::MetadataChopper.new("/tmp/metadata.rb")[:name].must_equal "banzai"
  end

  it "contains a :version attribute" do
    stub_metadata!("foobar", "1.2.3")
    Emeril::MetadataChopper.new("/tmp/metadata.rb")[:version].must_equal "1.2.3"
  end

  it "raises a MetadataParseError if name attribute is missing" do
    File.open("/tmp/metadata.rb", "wb") do |f|
      f.write [
        %{maintainer "Me"},
        %{maintainer_email "me@example.com"},
        %{version "1.2.3"}
      ].join("\n")
    end

    proc { Emeril::MetadataChopper.new("/tmp/metadata.rb") }.
      must_raise Emeril::MetadataParseError
  end

  it "raises a MetadataParseError if version attribute is missing" do
    File.open("/tmp/metadata.rb", "wb") do |f|
      f.write [
        %{maintainer "Me"},
        %{maintainer_email "me@example.com"},
        %{name "pants"}
      ].join("\n")
    end

    proc { Emeril::MetadataChopper.new("/tmp/metadata.rb") }.
      must_raise Emeril::MetadataParseError
  end

  private

  def stub_metadata!(name = "foobar", version = "5.2.1")
    File.open("/tmp/metadata.rb", "wb") do |f|
      f.write <<-METADATA_RB.gsub(/^ {8}/, "")
        name             "#{name}"
        maintainer       "Michael Bluth"
        maintainer_email "michael@bluth.com"
        license          "Apache 2.0"
        description      "Doing stuff!"
        long_description "Doing stuff!"
        version          "#{version}"
      METADATA_RB
    end
  end
end
