# Sewes

Welcome to the Simple Embedded WEb Server (SEWeS). It can be used to quickly
and easily add a web interface to your Ruby application. All you need to do
is to define the paths that your web server should respond to and hook up a
method that generates the respective HTML page.

Keep in mind that SEWeS is a very simple web server, so the feature set is
limited. It currently supports the following features.

* PUT and GET requests

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sewes'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sewes

## Usage

```ruby
require 'sewes'

class MyApp
  def initialize
  end

  def runApp
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scrapper/sewes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/scrapper/sewes/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Sewes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scrapper/sewes/blob/master/CODE_OF_CONDUCT.md).
