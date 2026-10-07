# Thermite

[![CI](https://github.com/danielpclark/thermite/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/danielpclark/thermite/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/malept/thermite/badges/gpa.svg)](https://codeclimate.com/github/malept/thermite)
[![Test coverage](https://codeclimate.com/github/malept/thermite/badges/coverage.svg)](https://codeclimate.com/github/malept/thermite/coverage)
[![Inline docs](http://inch-ci.org/github/malept/thermite.svg?branch=master)](http://inch-ci.org/github/malept/thermite)
[![Gem](https://img.shields.io/gem/v/thermite.svg?maxAge=30000)](https://rubygems.org/gems/thermite)

Thermite is a Rake-based helper for building and distributing Rust-based Ruby extensions.

## Features

* Provides wrappers for `cargo` commands.
* Handles non-standard `cargo` installations via the `CARGO` environment variable.
* Builds against the Ruby that runs Rake, by passing it to Cargo as the `RUBY` environment variable
  (which [Rutie](https://github.com/danielpclark/rutie) and `rb-sys` read to find libruby).
* Opt-in to allow users to install pre-compiled Rust extensions hosted on GitHub releases.
* Opt-in to allow users to install pre-compiled Rust extensions hosted on a third party server.
* Provides a wrapper for initializing a Rust extension via Fiddle.

## Usage

1. Add the following to your gemspec file:

  ```ruby
  spec.extensions << 'ext/Rakefile'
  spec.add_runtime_dependency 'thermite', '~> 0'
  ```

2. Create `ext/Rakefile` with the following code, assuming that the Cargo project root is the same
   as the Ruby project root:

  ```ruby
  require 'thermite/tasks'

  project_dir = File.dirname(File.dirname(__FILE__))
  Thermite::Tasks.new(cargo_project_path: project_dir, ruby_project_path: project_dir)
  task default: %w(thermite:build)
  ```

3. In `Rakefile`, integrate Thermite into your build-test workflow:

  ```ruby
  require 'thermite/tasks'

  Thermite::Tasks.new

  desc 'Run Rust & Ruby testsuites'
  task test: ['thermite:build', 'thermite:test'] do
    # …
  end
  ```

Run `rake -T thermite` to view all of the available tasks in the `thermite` namespace.

### Configuration

Task configuration for your project can be set in two ways:

* passing arguments to `Thermite::Tasks.new`
* adding a `package.metadata.thermite` section to `Cargo.toml`. These settings override the
  arguments passed to the `Tasks` class. Due to the conflict, it is infeasible for
  `cargo_project_path` or `cargo_workspace_member` to be set in this way. Example section:

```toml
[package.metadata.thermite]

github_releases = true
```

Possible options:

* `binary_uri_format` - if set, the interpolation-formatted string used to construct the download
  URI for the pre-built native extension. If the environment variable `THERMITE_BINARY_URI_FORMAT`
  is set, it takes precedence over this option. Either method of setting this option overrides the
  `github_releases` option.
  Example: `https://example.com/download/%{version}/%{filename}`. Replacement variables:
    - `filename` - The value of `Config.tarball_filename`
    - `version` - the crate version from `Cargo.toml`
* `cargo_project_path` - the path to the top-level Cargo project. Defaults to the current working
  directory.
* `cargo_workspace_member` - if set, the relative path to the Cargo workspace member. Usually used
  when it is part of a repository containing multiple crates.
* `github_releases` - whether to look for Rust binaries via GitHub releases when installing
  the gem, and `cargo` is not found. Defaults to `false`.
* `github_release_type` - when `github_releases` is `true`, the mode to use to download the Rust
  binary from GitHub releases. `'cargo'` (the default) uses the `version` option (described below),
  along with the `git_tag_format` option (described below) to determine the download URI. `'latest'` takes the
  latest release matching the `git_tag_regex` option (described below) to determine the download
  URI.
* `git_tag_format` - when `github_release_type` is `'cargo'` (the default), the
  [format string](http://ruby-doc.org/core/String.html#method-i-25) used to determine the tag used
  in the GitHub download URI. Defaults to `v%s`, where `%s` is the `version` option (described
  below).
* `git_tag_regex` - when `github_releases` is enabled and `github_release_type` is `'latest'`, a
  regular expression (expressed as a `String`) that determines which tagged releases to look for
  precompiled Rust tarballs. One group must be specified that indicates the version number to be
  used in the tarball filename. Defaults to the [semantic versioning 2.0.0
  format](https://semver.org/spec/v2.0.0.html). In this case, the group is around the entire
  expression.
* `optional_rust_extension` - prints a warning to STDERR instead of raising an exception, if Cargo
  is unavailable and `github_releases` is either disabled or unavailable. Useful for projects where
  either fallback code exists, or a native extension is desirable but not required. Defaults
  to `false`.
* `ruby_project_path` - the top-level directory of the Ruby gem's project. Defaults to the
  current working directory.
* `ruby_extension_dir` - the directory relative to `ruby_project_path` where the extension is
  located. Defaults to `lib`.
* `version` - the version of the extension, which names the tarball built by `thermite:tarball`
  and the release it is downloaded from. Defaults to the crate version in `Cargo.toml`; set it to
  the gem's version (e.g. `MyGem::VERSION`) when the two differ.

### Example: Rutie

[Rutie](https://github.com/danielpclark/rutie) 0.13 supports Ruby 3.2 to 3.4 (built with
`--enable-shared`). Declare the crate as a `cdylib` in `Cargo.toml`:

```toml
[lib]
crate-type = ["cdylib"]

[dependencies]
rutie = "0.13.1"
```

Write an `Init_<library name>` function in `src/lib.rs`, as described in Rutie's README, then build
it with `rake thermite:build` and load it from Ruby:

```ruby
require 'thermite/fiddle'

toplevel_dir = File.dirname(__dir__)
Thermite::Fiddle.load_module('Init_my_extension',
                             cargo_project_path: toplevel_dir,
                             ruby_project_path: toplevel_dir)
```

`Thermite::Fiddle` uses Ruby's `fiddle` library, which is not a default gem since Ruby 4.0. On
Ruby 4.0 or later, add `fiddle` to your gemspec or Gemfile to use it.

Rutie's build script links to whichever Ruby the `RUBY` environment variable names (or the first
`ruby` in the `PATH`). Thermite sets `RUBY` to the interpreter running Rake, unless it is already
set, so the extension always links to the same libruby that later loads it.

`test/fixtures/rutie_extension` contains a complete Rutie 0.13.1 extension. The integration test
that builds, tests, packages and loads it can be run with
`THERMITE_RUTIE_INTEGRATION=1 rake test` (it requires Cargo and a Ruby supported by Rutie).

While the example uses Rutie, this gem should be usable with any method of integrating Rust and
Ruby that you choose.

### Debug / release build

By default Thermite will do a release build of your Rust code. To do a debug build instead,
set the `CARGO_PROFILE` environment variable to `debug`.

For example, you can run `CARGO_PROFILE=debug rake thermite:build`.

### Troubleshooting

Debug statements can be written to a file specified by the `THERMITE_DEBUG_FILENAME` environment
variable.

## Code layout

Each part of Thermite is a small class that is handed everything it uses when it is created, so
that reading one file is enough to know where every method it calls comes from:

* `Thermite::Config` reads every outside value: task options, `Cargo.toml`, environment variables
  and `RbConfig`.
* `Thermite::Cargo` runs `cargo`.
* `Thermite::Builder` builds the library with Cargo, or downloads a pre-built one via
  `Thermite::CustomBinary` or `Thermite::GithubReleaseBinary` (which use `Thermite::Downloader`
  and `Thermite::HTTPClient`).
* `Thermite::Package` creates and installs tarballs, using `Thermite::InstallNameTool` on macOS.
* `Thermite::Tasks` creates those objects and defines the Rake tasks that call them.

## FAQ

### Why is it named Thermite?

According to Wikipedia:

* The chemical formula for ruby includes Al<sub>2</sub>O<sub>3</sub>, or aluminum oxide.
* Rust is iron oxide, or Fe<sub>2</sub>O<sub>3</sub>.
* A common thermite reaction uses iron oxide and aluminum to produce iron and aluminum oxide:
  Fe<sub>2</sub>O<sub>3</sub> + 2Al → 2Fe + Al<sub>2</sub>O<sub>3</sub>

## [Release Notes](https://github.com/malept/thermite/blob/master/NEWS.md)

## [Contributing](https://github.com/malept/thermite/blob/master/CONTRIBUTING.md)

## Legal

This gem is licensed under the MIT license.
