# Sewes

Welcome to the Simple Embedded WEb Server (SEWeS). It can be used to quickly
and easily add a web interface to your Ruby application. All you need to do
is to define the paths that your web server should respond to and hook up a
method that generates the respective HTML page.

Keep in mind that SEWeS is a very simple web server, so the feature set is
limited. It currently supports the following features.

* PUT and GET requests
* RFC6265 cookie support

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
require_relative '../lib/sewes'

# Simple example app to demonstrate the usage of SEWeS.
class SimpleApp
  HOSTNAME = 'localhost'.freeze

  def initialize
    @server = SEWeS::HTTPServer.new
  end

  def run
    # Register the methods that respond to HTTP GET requests.
    @server.get('favicon.ico') do |_|
      favicon
    end

    @server.get('hello') do |request|
      hello(request)
    end

    # Install our own 404 handler
    @server.not_found do |request|
      show404(request)
    end

    begin
      @server.start
      sleep(1)
      puts "Server is listening on port #{@server.port} on #{HOSTNAME}.\n" \
        'Press <Enter> to stop the server!'
      readline
    ensure
      @server.stop
    end
  end

  def favicon
    body = File.read('ruby_lang_logo_icon.ico', mode: 'rb')
    @server.response(body, content_type: 'image/ico').send
  end

  def hello(request)
    cookies = request.cookies
    body = html_page('Hello', "<h1>Hello, #{cookies.include?('greeting') ? 'again ' : ''}world!</h1>")
    response = @server.response(body)

    cookie = SEWeS::Cookie.new('greeting', 'hello')
    cookie.domain = HOSTNAME
    cookie.max_age = 300
    response.set_cookie(cookie)

    response
  end

  def show404(request)
    body = html_page('Error 404', "Page not found: #{request.path}")
    @server.response(body, code: 404)
  end

  private

  def html_page(title, body)
    body =
      <<~"HTML"
        <html>
          <head>
            <title>#{title}</title>
          </head>
          <body>
            #{body}
          </body>
        </html>
      HTML
  end
end

SimpleApp.new.run
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scrapper/sewes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/scrapper/sewes/blob/master/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the Sewes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scrapper/sewes/blob/master/CODE_OF_CONDUCT.md).
