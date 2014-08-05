# -*- encoding: utf-8 -*-

require_relative '../../spec_helper'
require 'chef/knife'
require 'chef/config'

require 'emeril/publisher'

class DummyKnife < Emeril::Publisher::SharePlugin

  def run; end
end

describe Emeril::Publisher do

  let(:cookbook_path)  { File.join(Dir.mktmpdir, "emeril") }
  let(:category)      { "Utilities" }

  let(:publisher) do
    if ENV['DEBUG']
      logger = Logger.new(STDOUT)
      logger.level = Logger::DEBUG
    else
      logger = nil
    end

    Emeril::Publisher.new(
      :source_path => cookbook_path,
      :name => "emeril",
      :category => category,
      :logger => logger,
      :knife_class => DummyKnife
    )
  end

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

  describe ".initialize" do

    it "raises an ArgumentError when :name is missing" do
      proc { Emeril::Publisher.new }.must_raise ArgumentError
    end
  end

  describe "#run" do

    before do
      make_cookbook!
    end

    after do
      FileUtils.remove_dir(cookbook_path)
    end

    it "constructs an instance of :knife_class" do
      knife_obj = DummyKnife.new
      DummyKnife.expects(:new).returns(knife_obj)

      publisher.run
    end

    it "sets a sandboxed cookbook_path on the knife object" do
      knife_obj = DummyKnife.new
      DummyKnife.stubs(:new).returns(knife_obj)
      sandbox_path = Dir.mktmpdir
      Dir.stub :mktmpdir, sandbox_path do
        publisher.run
      end

      knife_obj.config[:cookbook_path].must_equal sandbox_path
    end

    it "sets the cookbook name and category on the knife object" do
      knife_obj = DummyKnife.new
      DummyKnife.stubs(:new).returns(knife_obj)
      publisher.run

      knife_obj.name_args.must_equal ["emeril", category]
    end

    it "invokes run on the knife object" do
      knife_obj = DummyKnife.new
      DummyKnife.stubs(:new).returns(knife_obj)
      knife_obj.expects(:run)

      publisher.run
    end
  end

  describe "SharePlugin" do

    it "overrides #exit to raise an exception" do
      knife_obj = Emeril::Publisher::SharePlugin.new
      knife_obj.ui = Chef::Knife::UI.new(StringIO.new, StringIO.new,
        StringIO.new, knife_obj.ui.config)

      proc { knife_obj.run }.must_raise RuntimeError
    end
  end

  describe "LoggingUI" do

    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:stdin) { StringIO.new }

    let(:logger) do
      stub(:msg => true, :err => true, :warn => true, :fatal => true)
    end

    describe "#msg" do

      it "calls #logger.info if logger is set" do
        logger.expects(:info).with("yo")

        ui_with_logger.msg("yo")
      end

      it "calls super if logger is nil" do
        ui_without_logger.msg("yo")

        stdout.string.must_match /^yo$/
      end
    end

    describe "#err" do

      it "calls #logger.error if logger is set" do
        logger.expects(:error).with("yolo")

        ui_with_logger.err("yolo")
      end

      it "calls super if logger is nil" do
        ui_without_logger.err("yolo")

        stderr.string.must_match /^yolo$/
      end
    end

    describe "#warn" do

      it "calls #logger.warn if logger is set" do
        logger.expects(:warn).with("caution")

        ui_with_logger.warn("caution")
      end

      it "calls super if logger is nil" do
        ui_without_logger.err("caution")

        stderr.string.must_match /^caution$/
      end
    end

    describe "#fatal" do

      it "calls #logger.fatal if logger is set" do
        logger.expects(:fatal).with("die")

        ui_with_logger.fatal("die")
      end

      it "calls super if logger is nil" do
        ui_without_logger.fatal("die")

        stderr.string.must_match /die$/
      end
    end

    private

    def ui_with_logger
      Emeril::Publisher::LoggingUI.new(stdout, stderr, stdin, stub, logger)
    end

    def ui_without_logger
      Emeril::Publisher::LoggingUI.new(stdout, stderr, stdin, stub, nil)
    end
  end

  private

  def make_cookbook!
    FileUtils.mkdir_p("#{cookbook_path}/recipes")
    remote_dir = File.join(File.dirname(cookbook_path), "remote")

    File.open("#{cookbook_path}/metadata.rb", "wb") do |f|
      f.write <<-METADATA_RB.gsub(/^ {8}/, '')
        name             "#{name}"
        maintainer       "Michael Bluth"
        maintainer_email "michael@bluth.com"
        license          "Apache 2.0"
        description      "Doing stuff!"
        long_description "Doing stuff!"
        version          "4.1.1"
      METADATA_RB
    end
    File.open("#{cookbook_path}/recipes/default.rb", "wb") do |f|
      f.write <<-DEFAULT_RB.gsub(/^ {8}/, '')
        directory "/tmp/yeah"

        package "bash"
      DEFAULT_RB
    end
    File.open("#{cookbook_path}/Berksfile", "wb") { |f| f.write "borkbork" }
    File.open("#{cookbook_path}/.gitignore", "wb") { |f| f.write "Berksfile" }
  end
end
