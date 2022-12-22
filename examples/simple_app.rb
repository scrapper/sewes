require_relative '../lib/sewes'

class SimpleApp
  def initialize
    @server = SEWeS::HTTPServer.new
  end

  def run
    @server.add_route('GET', %w[favicon.ico], self, :favicon)
    @server.add_route('GET', %w[hello], self, :hello)

    begin
      @server.run
      sleep(1)
      puts "Server is listening on port #{@server.port} on localhost.\n" \
        "Press <Enter> to stop the server!"
      readline
    ensure
      @server.stop
    end
  end

  def favicon(_, _)
    body = File.read('ruby_lang_logo_icon.ico', mode: 'rb')
    @server.response(200, body, 'image/ico')
  end

  def hello(_, _)
    body =
      <<~HTML
        <html>
          <head>
            <title>Hello</title>
          </head>
          <body>
            <h1>Hello, world!</h1>
          </body>
        </html>
      HTML
    @server.response(200, body, 'text/html')
  end
end

SimpleApp.new.run
