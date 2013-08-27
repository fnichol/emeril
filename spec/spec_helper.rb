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

require 'chef'
require 'chef/cookbook_site_streaming_uploader'
class Chef
  class CookbookSiteStreamingUploader
    class MultipartStream
      alias_method :read_original, :read

      def read(how_much = nil)
        read_original(how_much || size)
      end
    end
  end
end

module Emeril

  module SpecCommon

    def make_cookbook!(opts = {})
      FileUtils.mkdir_p("#{cookbook_path}/recipes")
      remote_dir = File.join(File.dirname(cookbook_path), "remote")

      File.open("#{cookbook_path}/metadata.rb", "wb") do |f|
        f.write <<-METADATA_RB.gsub(/^ {10}/, '')
          name             "#{opts.fetch(:name, "emeril")}"
          maintainer       "Michael Bluth"
          maintainer_email "michael@bluth.com"
          license          "Apache 2.0"
          description      "Doing stuff!"
          long_description "Doing stuff!"
          version          "#{opts.fetch(:version, "4.1.1")}"
        METADATA_RB
      end
      File.open("#{cookbook_path}/recipes/default.rb", "wb") do |f|
        f.write <<-DEFAULT_RB.gsub(/^ {10}/, '')
          directory "/tmp/yeah"

          package "bash"
        DEFAULT_RB
      end
      File.open("#{cookbook_path}/README.md", "wb") do |f|
        f.write <<-README.gsub(/^ {10}/, '')
          # The beast of the beasts
        README
      end

      run_cmd [
        %{git init},
        %{git config user.email "you@example.com"},
        %{git config user.name "Your Name"},
        %{git add .},
        %{git commit -m "Initial"},
        %{git remote add origin #{remote_dir}},
        %{git init --bare #{remote_dir}}
      ].join(" && ")
    end

    def make_client_key!
      filename = "#{File.dirname(cookbook_path)}/client_key.pem"
      File.open(filename, "wb") do |f|
        f.write "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA0sOY9tHvVtLZ6xmVmH8d8LrRrNcWOXbrvvCrai+T3GtRvRSL\nhksLrpOpD0L9EHM6NdThNF/eGA9Oq+UKAe6yXR0hwsKuxKXqQ8SEmlhZZ9GiuggD\nB/zYD3ItB6SGpdkRe7kQqTChQyrIXqbRkJqxoTXLyeJDF0sCyTdp3L8IZCUWodM8\noV9TlQBJHYtG1gLUwIi8kcMVEoCn2Q8ltCj0/ftnwhTtwO52RkWA0uYOLGVayHsL\nSCFfx+ACWPU/oWCwW5/KBqb3veTv0aEg/nh0QsFzRLoTx6SRFI5dT2Nf8iiJe4WC\nUG8WKEB2G8QPnxsxfOPYDBdTJ4CXEi2e+z41VQIDAQABAoIBAALhqbW2KQ+G0nPk\nZacwFbi01SkHx8YBWjfCEpXhEKRy0ytCnKW5YO+CFU2gHNWcva7+uhV9OgwaKXkw\nKHLeUJH1VADVqI4Htqw2g5mYm6BPvWnNsjzpuAp+BR+VoEGkNhj67r9hatMAQr0I\nitTvSH5rvd2EumYXIHKfz1K1SegUk1u1EL1RcMzRmZe4gDb6eNBs9Sg4im4ybTG6\npPIytA8vBQVWhjuAR2Tm+wZHiy0Az6Vu7c2mS07FSX6FO4E8SxWf8idaK9ijMGSq\nFvIS04mrY6XCPUPUC4qm1qNnhDPpOr7CpI2OO98SqGanStS5NFlSFXeXPpM280/u\nfZUA0AECgYEA+x7QUnffDrt7LK2cX6wbvn4mRnFxet7bJjrfWIHf+Rm0URikaNma\nh0/wNKpKBwIH+eHK/LslgzcplrqPytGGHLOG97Gyo5tGAzyLHUWBmsNkRksY2sPL\nuHq6pYWJNkqhnWGnIbmqCr0EWih82x/y4qxbJYpYqXMrit0wVf7yAgkCgYEA1twI\ngFaXqesetTPoEHSQSgC8S4D5/NkdriUXCYb06REcvo9IpFMuiOkVUYNN5d3MDNTP\nIdBicfmvfNELvBtXDomEUD8ls1UuoTIXRNGZ0VsZXu7OErXCK0JKNNyqRmOwcvYL\nJRqLfnlei5Ndo1lu286yL74c5rdTLs/nI2p4e+0CgYB079ZmcLeILrmfBoFI8+Y/\ngJLmPrFvXBOE6+lRV7kqUFPtZ6I3yQzyccETZTDvrnx0WjaiFavUPH27WMjY01S2\nTMtO0Iq1MPsbSrglO1as8MvjB9ldFcvp7gy4Q0Sv6XT0yqJ/S+vo8Df0m+H4UBpU\nf5o6EwBSd/UQxwtZIE0lsQKBgQCswfjX8Eg8KL/lJNpIOOE3j4XXE9ptksmJl2sB\njxDnQYoiMqVO808saHVquC/vTrpd6tKtNpehWwjeTFuqITWLi8jmmQ+gNTKsC9Gn\n1Pxf2Gb67PqnEpwQGln+TRtgQ5HBrdHiQIi+5am+gnw89pDrjjO5rZwhanAo6KPJ\n1zcPNQKBgQDxFu8v4frDmRNCVaZS4f1B6wTrcMrnibIDlnzrK9GG6Hz1U7dDv8s8\nNf4UmeMzDXjlPWZVOvS5+9HKJPdPj7/onv8B2m18+lcgTTDJBkza7R1mjL1Cje/Z\nKcVGsryKN6cjE7yCDasnA7R2rVBV/7NWeJV77bmzT5O//rW4yIfUIg==\n-----END RSA PRIVATE KEY-----\n"
      end
      filename
    end

    def run_cmd(cmd, opts = {})
      %x{cd #{opts.fetch(:in, cookbook_path)} && #{cmd}}
    end
  end
end
