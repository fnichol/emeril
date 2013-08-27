# -*- encoding: utf-8 -*-

require_relative '../../spec_helper'
require 'tmpdir'
require 'logger'

require 'emeril/git_tagger'

describe Emeril::GitTagger do

  include Emeril::SpecCommon

  let(:cookbook_path)  { File.join(Dir.mktmpdir, "emeril") }

  let(:git_tagger) do
    Emeril::GitTagger.new(
      :source_path => cookbook_path,
      :version => "4.1.1",
      :logger => nil
    )
  end

  describe ".initialize" do

    it "raises an ArgumentError when :version is missing" do
      proc { Emeril::GitTagger.new }.must_raise ArgumentError
    end
  end

  describe "#run" do

    before do
      make_cookbook!
    end

    after do
      FileUtils.remove_dir(cookbook_path)
    end

    it "tags the repo" do
      git_tagger.run
      run_cmd(%{git tag}).must_match /^v4.1.1$/
    end

    it "disables the tag prefix" do
      Emeril::GitTagger.new(
        :source_path => cookbook_path,
        :version => "4.1.1",
        :logger => nil,
        :tag_prefix => false
      ).run

      run_cmd(%{git tag}).must_match /^4.1.1$/
    end

    it "uses a custom tag prefix" do
      Emeril::GitTagger.new(
        :source_path => cookbook_path,
        :version => "4.1.1",
        :logger => nil,
        :tag_prefix => "version-"
      ).run

      run_cmd(%{git tag}).must_match /^version-4.1.1$/
    end

    it "pushes the tag to the remote" do
      git_tagger.run

      run_cmd(%{git ls-remote --tags origin}).
        must_match %r{refs/tags/v4\.1\.1$}
    end

    describe "when git repo is not clean" do

      before do
        File.open("#{cookbook_path}/README.md", "wb") { |f| f.write "Yep." }
      end

      it "raises GitNotCleanError" do
        proc { git_tagger.run }.must_raise Emeril::GitNotCleanError
      end
    end

    describe "when git tag exists" do

      before do
        run_cmd %{git tag v4.1.1}
      end

      it "skips tagging" do
        git_tagger.expects(:tag_version).never

        git_tagger.run
      end
    end

    describe "when no git remote exists" do

      before do
        run_cmd %{git remote rm origin}
      end

      it "raises GitPushError" do
        proc { git_tagger.run }.must_raise Emeril::GitPushError
      end
    end
  end
end
