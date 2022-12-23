require_relative '../lib/sewes'

# Simple example app to demonstrate the usage of SEWeS. The cookie setting
# only works with Firefox as other browsers ignore cookies from localhost.
class SimpleApp
  HOSTNAME = 'localhost'.freeze

  def initialize
    @server = SEWeS::HTTPServer.new
  end

  def run
    # Register the methods that respond to HTTP GET requests.
    @server.add_route('GET', %w[favicon.ico], self, :favicon)
    @server.add_route('GET', %w[hello], self, :hello)

    begin
      @server.run
      sleep(1)
      puts "Server is listening on port #{@server.port} on #{HOSTNAME}.\n" \
        'Press <Enter> to stop the server!'
      readline
    ensure
      @server.stop
    end
  end

  def favicon(_, _)
    body = File.read('ruby_lang_logo_icon.ico', mode: 'rb')
    @server.response(body, content_type: 'image/ico').send
  end

  def hello(_, request)
    cookies = request.cookies
    body =
      <<~"HTML"
        <html>
          <head>
            <title>Hello</title>
          </head>
          <body>
            <h1>Hello, #{cookies.include?('greeting') ? 'again ' : ''}world!</h1>
          </body>
        </html>
      HTML
    response = @server.response(body, content_type: 'text/html')
    cookie = SEWeS::Cookie.new('greeting', 'hello')
    cookie.domain = HOSTNAME
    cookie.max_age = 300
    response.set_cookie(cookie)

    response
  end
end

SimpleApp.new.run
