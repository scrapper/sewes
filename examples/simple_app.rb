# frozen_string_literal: true

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
    cookies = request.headers.cookies
    body = html_page('Hello', "<h1>Hello, #{cookies.include?('greeting') ? 'again ' : ''}world!</h1>")
    response = @server.response(body)

    cookie = SEWeS::Cookie.new('greeting', 'hello')
    cookie.domain = HOSTNAME
    cookie.max_age = 300
    response.headers['set-cookie'] = cookie

    response
  end

  def show404(request)
    body = html_page('Error 404', "Page not found: #{request.path}")
    @server.response(body, code: 404)
  end

  private

  def html_page(title, body)
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
