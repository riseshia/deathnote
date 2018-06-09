# Deathnote

deathnote gem receive 2 commit hash and compare those dead code from each version of project code.
This will be helpful if you have a lot false-positive result.

You may get better understanding with [this slide](https://speakerdeck.com/riseshia/find-out-potential-dead-codes-from-diff).

## Requirement

deathnote assumes you are using git.
It will use `git checkout` to switch to each revision.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'deathnote', require: false
```

Or install it yourself as:

    $ gem install deathnote

## Usage

```
Usage: deathnote [options] files_or_dirs
    -h, --help                       Display this help.
    -p, --past-commit=[commit hash]  Specify past commit hash.
    -n, --newer-commit=[commit hash] Specify newer commit hash.
    -r, --rails                      Filter some rails call conversions.
    -w, --whitelist                  Whitelist with separated by \n
    -e, --exclude=file1,file2,etc    Exclude files or directories in comma-separated list.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/riseshia/deathnote.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
