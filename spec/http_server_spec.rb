# frozen_string_literal: true

require 'socket'
require 'net/http'
require 'uri'
require 'rspec'

require_relative '../lib/sewes/http_server'

# Basic HTML page for testing
class TestPage
  def initialize(srv)
    @srv = srv
  end

  def render(_)
    @srv.response('Hello, world!')
  end
end

RSpec.describe SEWeS::HTTPServer do
  describe 'Basic start and stop operation' do
    it 'should create a server and stop it again' do
      start_server
      stop_server
    end

    it 'should respond to a http GET request' do
      start_server

      tp = TestPage.new(@srv)
      @srv.get('hello') do |r|
        tp.render(r)
      end
      response = Net::HTTP.get(URI("http://localhost:#{@srv.port}/hello"))
      expect(response).to eql('Hello, world!')
      expect(@srv.statistics.requests['GET']).to eql(1)

      stop_server
    end
  end

  describe 'Test of error conditions' do
    it 'should error on empty requests' do
      messages = [["\n"]]

      responses = exchange_messages(messages)
      # Body starts at line 5
      expect(responses.first.split("\r\n")[5]).to eql('Request is empty')
      expect(@srv.statistics.errors[400]).to be >= 1
    end

    it 'should error on unknown route' do
      start_server

      response = Net::HTTP.get(URI("http://localhost:#{@srv.port}"))
      expect(response).to eql('Path not found: /')
      expect(@srv.statistics.errors[404]).to eql(1)

      stop_server
    end

    it 'should error on bad method' do
      messages = [
        [<<~"MSG"
          HONK /foo/bar/ HTTP/1.1
          HOST: hostname
          Connection: Close
          Content-Type: application/x-www-form-urlencoded
          Content-Length: 7

          a=b&c=d
        MSG
        ]
      ]
      exchange_messages(messages)
      expect(@srv.statistics.errors[405]).to eql(1)
    end

    it 'should error on too large content length' do
      messages = [
        [<<~"MSG"
          POST /foo/bar/ HTTP/1.1
          HOST: hostname
          Connection: Close
          Content-Type: application/x-www-form-urlencoded
          Content-Length: 999999

          a=b&c=d
        MSG
        ]
      ]
      exchange_messages(messages)
      expect(@srv.statistics.errors[413]).to eql(1)
    end

    it 'should error on content length not matching body size' do
      messages = [
        [<<~"MSG"
          POST /foo/bar/ HTTP/1.1
          HOST: hostname
          Connection: Close
          Content-Type: application/x-www-form-urlencoded
          Content-Length: 999

          a=b&c=d
        MSG
        ]
      ]
      exchange_messages(messages)
      expect(@srv.statistics.errors[408]).to eql(1)
    end
  end

  #
  # Utility methods
  #
  def exchange_messages(messages)
    start_server

    responses = []
    messages.each do |message|
      sock = TCPSocket.new('localhost', @srv.port)
      message.each do |section|
        sock.print(section.gsub(/\n/, "\r\n"))
        responses << sock.readpartial(2048)
      end
    end

    stop_server

    responses
  end

  def start_server
    log = StringIO.new
    @srv = SEWeS::HTTPServer.new(log: log)
    @thr = Thread.new do
      @srv.start
    end

    sleep(1)
  end

  def stop_server
    @srv.stop

    sock = TCPSocket.new('localhost', @srv.port)
    sock.puts "\r\n\r\n"
    sock.close
    @thr.join
  end
end
