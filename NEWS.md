# Changes by Version

## [0.14.0] - 2026-10-07

### Added

* A `version` option (also settable in `package.metadata.thermite`): the version that names the
  tarball built by `thermite:tarball` and the release it is downloaded from, for gems whose
  version is not their crate's. Defaults to the crate version, as before
* `cargo` is run with the `RUBY` environment variable set to the Ruby running Thermite (unless it
  is already set), so that Rutie and `rb-sys` build scripts link to the right libruby
* An opt-in integration test that builds, tests, packages and loads a Rutie 0.13.1 extension
* GitHub Actions CI on Linux, macOS and Windows (replacing Travis CI and AppVeyor), including the
  Rutie integration test on Ruby 3.2 to 3.4

### Changed

* The default `git_tag_regex` conforms more to the semantic versioning 2.0.0 spec (#46)
* Ruby 2.5 or later is required
* RuboCop 1.x checks the code (0.93 could not run on Ruby 3.4); as it needs Ruby 2.7, the
  Gemfile leaves it out on older Rubies
* The helper modules that `Thermite::Tasks` included (`Cargo`, `CustomBinary`,
  `GithubReleaseBinary`, `Package` and `Util`) are replaced by classes that are given their
  dependencies explicitly. Code that included those modules, or called their methods on a
  `Thermite::Tasks` object, needs to use the new classes instead. `Thermite::Tasks.new`,
  `Thermite::Tasks#config`, `Thermite::Tasks#options`, `Thermite::Config.new` and
  `Thermite::Fiddle.load_module` are unchanged
* `Thermite::Config` applies the `package.metadata.thermite` section of `Cargo.toml` itself, so
  `Thermite::Fiddle.load_module` now respects settings such as `ruby_extension_dir` made there
* `Thermite::Tasks.new` no longer modifies the options hash passed to it
* `cargo` is found without `mkmf`, so no `checking for cargo...` output or `mkmf.log` is produced
* `Thermite::Fiddle` needs the `fiddle` gem to be declared on Ruby 4.0 or later, where it is no
  longer a default gem

### Fixed

* `rexml` is declared as a dependency, since it is not a default gem since Ruby 3.0
* The default `git_tag_regex` matched any character between the version numbers, not only a dot
* On macOS, `thermite:tarball` no longer leaves the built library unloadable: the libruby path
  is now rewritten in a copy of the library that is packaged, not in the installed library
* Too many HTTP redirects raised a `NameError` instead of a redirect error
* All HTTP redirect types (including relative `Location` headers) are followed
* `install_name_tool` is run without a shell (`shellwords` was used without being required)

## [0.13.0] - 2017-10-05

### Added

* Support for building static libraries (#22, #41):

### Fixed

* Always pass `--lib` to `cargo with `link-args` (#40)

## [0.12.1] - 2017-04-06

### Fixed

* Default target directory (when the CARGO_TARGET_DIR is not set)

## [0.12.0] - 2017-04-05

### Added

* Support for CARGO_TARGET_DIR environment variable (#33)

### Fixed

* Cargo executable and arguments with paths using spaces are supported properly

### Changed

* CARGO_TARGET is now CARGO_PROFILE, for less confusion (#35)

## [0.11.1] - 2017-02-04

### Fixed

* Add support for Cargo workspaces to `thermite:clean` and `thermite:test`

## [0.11.0] - 2017-02-03

### Added

* Add support for Cargo workspaces (#30)

## [0.10.0] - 2017-01-22

### Fixed

* Adjust OSX dylib library paths upon installation (#28)
* Don't use UNIX shell escaping on Windows

### Changed

* `cargo build` has been replaced by `cargo rustc` - non-Windows builds use DLDFLAGS as linker
  arguments (#27)

## [0.9.0] - 2017-01-18

### Fixed

* The library name is consistent with how Cargo handles hyphens (#19)
* Raise error if using GitHub Releases & repository not in `Cargo.toml` (#18)

## [0.8.0] - 2016-12-05

### Added

* Support for binary download URIs from non-GitHub sources (#17)

### Changed

* Tarballs are installed relative to `ruby_project_path`

## [0.7.0] - 2016-09-26

### Added

* Helper module for loading extensions via Fiddle (#13)

## [0.6.0] - 2016-09-12

### Added

* `optional_rust_extension` option - prints a warning to STDERR instead of raising an exception, if
  Cargo is unavailable and `github_releases` is either disabled or unavailable. Useful for projects
  where either fallback code exists, or a native extension is desirable but not required. (#4, #6)

### Fixed

* `cargo` was not being run in the context of the rust project toplevel directory (#7, #8)

## [0.5.0] - 2016-07-18

### Added

* Unit tests and code coverage (including new development dependencies)
* CI support on OSX and Windows in addition to Linux
* Successful CI builds on Linux trigger rusty_blank CI builds on Linux/OSX/Windows

### Changed

* Documentation uses YARD instead of RDoc
* `unpack_tarball` is a public method

### Fixed

* Documentation for `debug`
* Windows platform support

## [0.4.0] - 2016-07-12

### Added

* Write debug output to file, if the `THERMITE_DEBUG_FILENAME` environment variable is set

### Changed

* Relaxed rake version requirement
* Ruby version (major + minor) is considered when generating tarball names

### Fixed

* The library path in the generated tarballs is relative

## [0.3.0] - 2016-07-03

### Added

* `github_release_type`, to add `'cargo'` releases via `Cargo.toml` (default) in addition to the
  existing `'latest'` functionality

### Changed

* `git_tag_format` option introduced in 0.2.0 renamed to `git_tag_regex` - `git_tag_format` is
  specific to `github_release_type: 'cargo'`, while `git_tag_regex` is specific to
  `github_release_type: 'latest'`

## [0.2.0] - 2016-06-30

### Added

* Config options can be set in `Cargo.toml` (and overrides the options set in the `Thermite::Tasks`
  constructor)

### Changed

* Git tag formats are configurable via `git_tag_format` - defaults to basic semver format

### Fixed

* Accessing the TOML config file when searching for Rust binaries

## [0.1.0] - 2016-06-28

Initial release.

[0.13.0]: https://github.com/malept/thermite/compare/v0.12.1...v0.13.0
[0.12.1]: https://github.com/malept/thermite/compare/v0.12.0...v0.12.1
[0.12.0]: https://github.com/malept/thermite/compare/v0.11.1...v0.12.0
[0.11.1]: https://github.com/malept/thermite/compare/v0.11.0...v0.11.1
[0.11.0]: https://github.com/malept/thermite/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/malept/thermite/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/malept/thermite/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/malept/thermite/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/malept/thermite/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/malept/thermite/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/malept/thermite/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/malept/thermite/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/malept/thermite/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/malept/thermite/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/malept/thermite/releases/tag/v0.1.0
