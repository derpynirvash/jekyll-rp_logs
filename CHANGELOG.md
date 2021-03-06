# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [0.2.1] - 2015-10-26
### Fixed
- Lines whose contents are completely whitespace are parsed correctly ([#40])

## [0.2.0] - 2015-10-26
### Added
- The RP log directory can now be renamed ([#15])
- Two config options to control the inner workings of the plugin: ([#38])
  - `max_seconds_between_posts` - for the time limit on post merges
  - `ooc_start_delimiters` - for what characters denote the start of OOC text ([#25])
- `splits_by_character` setting to correctly handle clients that don't split by word ([#23])
- Informational messages when converting RPs (can be quieted using Jekyll's config settings) ([#31])
- Unit tests for most files, making development a lot easier
- `time_line` option to allow RPs to be custom sorted inside arcs
- Set up code linting with [RuboCop](https://github.com/bbatsov/rubocop)
- Set up [Travis CI testing](https://travis-ci.org/xiagu/jekyll-rp_logs) and code coverage + [CodeClimate](https://codeclimate.com/github/xiagu/jekyll-rp_logs) ([#18])
- `!MERGE` flag to force lines to merge ([#8])
- `!SPLIT` flag to force lines to stay separate  ([#7])
- Rake task `deploy` to set up a development site ([#4])
- Rake task `serve` to deploy and then serve a development site ([#4])

### Changed
- Instead of just `(`, `[` now denotes OOC by default too ([#25])
- Warnings when errors are encountered now use Jekyll's logger
- Switched to using a wrapper class, `Jekyll::RpLogs::Page`, instead of just raw `Jekyll::Page`
- `Parser` now has default values for some regular expression matchers that are commonly used:
  - `MODE`, `NICKS`, and `FLAGS`
- Double quotes are used (nearly) universally

### Removed
- `LogLine` is no longer an inner class of `Parser`. This will break any custom parsers written.
- Most methods of `RpLogGenerator` are private now, but this shouldn't break anything unless you were doing naughty things with it.

### Fixed
- Clients who split posts in the middle of words can be handled correctly now ([#23])
- The RP log directory is renameable again ([#15])
- You can actually turn off conversion now
- Special HTML characters are escaped in input text ([#11])
- The time difference in merged lines needs to be non-negative
- Set required Ruby version to `~> 2.1` ([#32])


[0.2.1]: https://github.com/xiagu/jekyll-rp_logs/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/xiagu/jekyll-rp_logs/compare/v0.1.6...v0.2.0

[#11]: https://github.com/xiagu/jekyll-rp_logs/issues/11
[#15]: https://github.com/xiagu/jekyll-rp_logs/issues/15
[#23]: https://github.com/xiagu/jekyll-rp_logs/issues/23
[#25]: https://github.com/xiagu/jekyll-rp_logs/issues/25
[#31]: https://github.com/xiagu/jekyll-rp_logs/issues/31
[#32]: https://github.com/xiagu/jekyll-rp_logs/issues/32
[#18]: https://github.com/xiagu/jekyll-rp_logs/issues/18
[#38]: https://github.com/xiagu/jekyll-rp_logs/issues/38
[#8]: https://github.com/xiagu/jekyll-rp_logs/issues/8
[#7]: https://github.com/xiagu/jekyll-rp_logs/issues/7
[#4]: https://github.com/xiagu/jekyll-rp_logs/issues/4
[#40]: https://github.com/xiagu/jekyll-rp_logs/issues/40
