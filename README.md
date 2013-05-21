# <a name="title"></a> Emeril: Tag And Release Chef Cookbooks As A Library

[![Build Status](https://travis-ci.org/fnichol/emeril.png?branch=master)](https://travis-ci.org/fnichol/emeril)
[![Dependency Status](https://gemnasium.com/fnichol/emeril.png)](https://gemnasium.com/fnichol/emeril)
[![Code Climate](https://codeclimate.com/github/fnichol/emeril.png)](https://codeclimate.com/github/fnichol/emeril)

Kick it up a notch! Emeril is a library that helps you release your Chef
cookbooks from Rake, Thor, or a Ruby library. If `rake release` is all you
are after, this should fit the bill.

## <a name="tl-dr"></a> tl;dr

How do you get started? Without much fanfare&hellip;

```sh
echo "gem 'emeril'" > Gemfile
bundle install
echo "require 'emeril/rake'" > Rakefile
bundle exec rake release
```

**Bam!**

Need more details? Read on&hellip;

## <a name="how-it-works"></a> How It Works

Emeril has 2 primary tasks and goals:

1. Tag a Git commit with a semantic version tag with the form `"v1.2.5"` (by
   default)
2. Publish a versioned release of the cookbook to the
   [Community Site][community_site]

The Git tagging is currently accomplished via shell out, so Git must be
installed on your system.

In order to bypass the deeply coupled `cookbook_path` assumptions that exist
in the Knife plugins, the publishing task (implemented by the
[Publisher class][publisher_class]) will create a temporary sandboxed copy
of the primary cookbook files for use by the
[CookbookSiteShare][knife_plugin] Knife plugin. The following files are
considered production cookbook files:

* `README.*`
* `CHANGELOG.*`
* `metadata.{json,rb}`
* `attributes/**/*`
* `files/**/*`
* `libraries/**/*`
* `providers/**/*`
* `recipes/**/*`
* `resources/**/*`
* `templates/**/*`

If the above list seems incomplete or incorrect, please submit an
[issue][issues].

## <a name="installation"></a> Installation

Add this line to your application's Gemfile:

```ruby
gem 'emeril'
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install emeril
```

## <a name="usage"></a> Usage

### <a name="usage-setup"></a> Credentials Setup

Emeril currently uses the [CookbookSiteShare][knife_plugin] to do most of the
heavy lifting, so you will need a minimally configured [knife.rb][knife_rb]
file with some required attributes set.

There are 2 configuration items you need:

1. Your [Community Site][community_site] username, chosen at signup time.
2. The file path to your [Community Site][community_site] user certificate.
   When you sign up to the Community Site, the site will provide this key to
   you as a `*.pem` file.

The easiest way to get setup is to add both of these items to your default
`knife.rb` file located at `$HOME/.chef/knife.rb`. If you are setting this
file up for the first time, give this a go (substituting your username, and
key location):

```sh
mkdir -p $HOME/.chef
cat <<KNIFE_RB > $HOME/.chef/knife.rb
node_name     "fnichol"
client_key    File.expand_path('~/.chef/fnichol.pem')
KNIFE_RB
```

### <a name="usage-rake"></a> Rake Tasks

To add the default Rake task (`rake release`), add the following to your
`Rakefile`:

```ruby
require 'emeril/rake'
```

If you need to further customize the `Emeril::Releaser` object you can use
the more explicit format with a block:

```ruby
require 'emeril/rake_tasks'

Emeril::RakeTasks.new do |t|
  # turn on debug logging
  t.config[:logger].level = :debug

  # disable git tag prefix string
  t.config[:tag_prefix] = false

  # set a category for this cookbook
  t.config[:category] = "Applications"
end
```

### <a name="usage-rake"></a> Thor Tasks

To add the default Thor task (`thor emeril:release`), add the following to your
`Thorfile`:

```ruby
require 'emeril/thor'
```

If you need to further customize the `Emeril::Releaser` object you can use
the more explicit format with a block:

```ruby
require 'emeril/thor_tasks'

Emeril::ThorTasks.new do |t|
  # turn on debug logging
  t.config[:logger].level = :debug

  # disable git tag prefix string
  t.config[:tag_prefix] = false

  # set a category for this cookbook
  t.config[:category] = "Applications"
end
```

### <a name="usage-ruby"></a> Ruby Library

The Ruby API is fairly straight forward, but keep in mind that loading or
populating `Chef::Config[:node_name]` and `Chef::Config[:client_key]` is
the responsibility of the caller, not Emeril.

For example, to load configuration from [knife.rb][knife_rb] and invoke the
same code as the default Rake and Thor tasks, use the following:

```ruby
# Populate Chef::Config from knife.rb
require 'chef/knife'
Chef::Knife.new.configure_chef

# Perform the git tagging and share to the Community Site
require 'emeril'
Emeril::Releaser.new(logger: Chef::Log).run
```

## <a name="faq"></a> Frequently Asked Questions

* **"Why doesn't Emeril automatically bump version numbers?"**
  Emeril assumes that you are using a [Semantic Versioning][semver_site] scheme
  for your cookbooks. Consequently it is very hard to determine what the
  next version number should be when this number is coupled to the changes
  accompanying the release. The next release could contain a bug fix, a new
  feature, or contain a backwards incompatible change--all of which have a
  bearing on the version number.
* **"Okay, what if I supplied the version number, couldn't Emeril help me
  then?"** Perhaps, but don't forget the other essential release artifact:
  a project [changelog][changelog_wikipedia]. While the maintenance schedule
  of the changelog is up to each author, it is sometimes desirable to
  combine the version bump and changelog items in [one][ex1] [git][ex2]
  [commit][ex3]. Emeril will tag and release your cookbook based on the
  last Git commit which is presumably your *version-bump-and-changelog*
  commit.
* **"How do I change the category for my cookbook?"** Emeril will maintain
  the category used on the Community Site across releases. By default, new
  cookbooks will be put in the `"Other"` category. For now you can change
  the category directly on the Community Site, done! Otherwise, check out
  the [Rake](#usage-rake) and [Thor](#usage-thor) sections for further
  configuration help.
* **"Why is Emeril complaining that I'm missing the name attribute in my
  metadata.rb?"** You want to set this name attribute. It unambiguously sets
  the name of the cookbook and not the directory name that happens to contain
  the cookbook code. Modern tools such as [Berkshelf][berkshelf_site] require
  this for dependency resolution and the [Foodcritic][foodcritic_site]
  cookbook linting tool has rule [FC045][fc045] to help catch this omission.

## <a name="alternatives"></a> Alternatives

* [knife-community][knife_community] - a more complete, workflow-enabled tool
  by [Mike Fiedler](https://github.com/miketheman).
* [knife community site share][knife_share] - with some extra/manual git
  tagging, correct directory structure, and workflow. Ships with the
  [Chef gem][chef_gem].

## <a name="development"></a> Development

* Source hosted at [GitHub][repo]
* Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## <a name="authors"></a> Authors

Created and maintained by [Fletcher Nichol][fnichol] (<fnichol@nichol.ca>)

## <a name="license"></a> License

MIT (see [LICENSE.txt][license])

[license]:      https://github.com/fnichol/emeril/blob/master/LICENSE.txt
[fnichol]:      https://github.com/fnichol
[repo]:         https://github.com/fnichol/emeril
[issues]:       https://github.com/fnichol/emeril/issues
[contributors]: https://github.com/fnichol/emeril/contributors

[berkshelf_site]:   http://berkshelf.com/
[changelog_wikipedia]: http://en.wikipedia.org/wiki/Changelog
[chef_gem]:         https://github.com/opscode/chef
[community_site]:   http://community.opscode.com/
[ex1]:              https://github.com/fnichol/chef-ruby_build/commit/c940b5e9cd40eaba10d6285de6648f4d25fe959d
[ex2]:              https://github.com/fnichol/chef-homesick/commit/80e558ff921f1c59698f6942214c0224a24392d7
[ex3]:              https://github.com/fnichol/chef-openoffice/commit/bf84aba0690a6b155b499b06df953be19a3aead1
[fc045]:            http://acrmp.github.io/foodcritic/#FC045
[foodcritic_site]:  http://acrmp.github.io/foodcritic/
[knife_plugin]:     https://github.com/opscode/chef/blob/master/lib/chef/knife/cookbook_site_share.rb
[knife_rb]:         http://docs.opscode.com/config_rb_knife.html
[knife_community]:  http://miketheman.github.io/knife-community/
[knife_share]:      http://docs.opscode.com/knife_cookbook_site.html#share
[publisher_class]:  https://github.com/fnichol/emeril/blob/master/lib/emeril/publisher.rb
[semver_site]:      http://semver.org/
