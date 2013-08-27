# -*- encoding: utf-8 -*-

require_relative '../../spec_helper'

require 'emeril/releaser'

describe Emeril::Releaser do

  let(:metadata) do
    { :name => "foobar", :version => "4.2.0" }
  end
  let(:source_path) { "/tmp/yep" }
  let(:category)    { "Databases" }
  let(:git_tagger)  { stub(:run => true) }
  let(:publisher)   { stub(:run => true) }

  before do
    @saved = Hash.new
    %w{node_name client_key}.map(&:to_sym).each do |attr|
      @saved[attr] = Chef::Config[attr]
    end

    Chef::Config[:node_name] = "buster"
    Chef::Config[:client_key] = "/tmp/buster.pem"
  end

  after do
    %w{node_name client_key}.map(&:to_sym).each do |attr|
      Chef::Config[attr] = @saved.delete(attr)
    end
  end

  describe ".initalize" do

    it "defaults :source_path to current path" do
      Emeril::GitTagger.expects(:new).with do |opts|
        opts[:source_path] == Dir.pwd
      end
      Emeril::Publisher.expects(:new).with do |opts|
        opts[:source_path] == Dir.pwd
      end

      Emeril::Releaser.new(:metadata => metadata, :category => category)
    end

    it "sets a custom :source_path" do
      Emeril::GitTagger.expects(:new).with do |opts|
        opts[:source_path] == source_path
      end
      Emeril::Publisher.expects(:new).with do |opts|
        opts[:source_path] == source_path
      end

      Emeril::Releaser.new(:metadata => metadata, :category => category,
        :source_path => source_path)
    end

    it "defaults :metadata to use MetadataChopper" do
      Emeril::MetadataChopper.expects(:new).with { |path|
        path =~ /#{File.join(source_path, "metadata.rb")}$/
      }.returns({ :name => "c", :version => "1.0.0" })

      Emeril::Releaser.new(:category => category, :source_path => source_path)
    end

    it "defaults :category to use Category.for_coobook" do
      Emeril::Category.expects(:for_cookbook).with("wakka")

      Emeril::Releaser.new({
        :metadata => { :name => "wakka", :version => "1.0.0" }
      })
    end

    it "defaults :git_tagger to use GitTagger" do
      Emeril::GitTagger.expects(:new).with do |opts|
        opts[:source_path] == source_path &&
          opts[:version] == metadata[:version]
      end

      Emeril::Releaser.new(
        :source_path => source_path,
        :metadata => metadata,
        :category => category
      )
    end

    it "defaults :publisher to use Publisher" do
      Emeril::Publisher.expects(:new).with do |opts|
        opts[:source_path] == source_path &&
          opts[:name] == metadata[:name] &&
          opts[:category] == category
      end

      Emeril::Releaser.new(
        :source_path => source_path,
        :metadata => metadata,
        :category => category
      )
    end

    it "does not call Publisher when disabling community site publishing" do
      Emeril::Publisher.expects(:new).never

      Emeril::Releaser.new(
        :source_path => source_path,
        :metadata => metadata,
        :category => category,
        :publish_to_community => false
      )
    end

    it "disables the git version tag prefix" do
      Emeril::GitTagger.expects(:new).with do |opts|
        opts[:tag_prefix] == false
      end

      Emeril::Releaser.new(
        :source_path => source_path,
        :metadata => metadata,
        :category => category,
        :tag_prefix => false
      )
    end
  end

  describe "#run" do

    it "calls #run on git_tagger" do
      releaser = Emeril::Releaser.new(
        :metadata => metadata,
        :category => category,
        :git_tagger => git_tagger,
        :publisher => publisher
      )
      git_tagger.expects(:run)

      releaser.run
    end

    it "calls #run on publisher" do
      releaser = Emeril::Releaser.new(
        :metadata => metadata,
        :category => category,
        :git_tagger => git_tagger,
        :publisher => publisher
      )
      publisher.expects(:run)

      releaser.run
    end

    describe 'when disabling community site publishing' do
      it 'does not call #run on publisher' do
        releaser = Emeril::Releaser.new(
          :metadata => metadata,
          :category => category,
          :git_tagger => git_tagger,
          :publisher => publisher,
          :publish_to_community => false
        )
        publisher.unstub(:run)
        publisher.expects(:run).never

        releaser.run
      end

    end
  end
end
