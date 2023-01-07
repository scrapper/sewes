# frozen_string_literal: true

require_relative '../lib/sewes/headers'

RSpec.describe SEWeS::Headers do
  it 'should support set-cookies' do
    h = SEWeS::Headers.new
    c1 = SEWeS::Cookie.new('foo', 'bar')
    h.set_cookie(c1)
    expect(h['set-cookie']).to eql(c1)
    expect(h.to_s).to eql("set-cookie: foo=bar\r\n\r\n")

    c2 = SEWeS::Cookie.new('foobar', 'barfoo')
    h.set_cookie(c2)
    expect(h['set-cookie']).to eql([c1, c2])
    expect(h.to_s).to eql("set-cookie: foo=bar\r\nset-cookie: foobar=barfoo\r\n\r\n")
  end

  it 'should support parsing headers and extracting cookies' do
    s = "location: some/place/else\r\n" \
      "cookie: foo=bar; valid=true;\r\n" \
      " foobar=barfoo\r\n\r\n"
    h = SEWeS::Headers.new
    h.parse(s.lines + ["\r\n"])
    expect(h['location']).to eql('some/place/else')
    expect(h.cookies).to eql({ 'foo' => 'bar', 'valid' => 'true', 'foobar' => 'barfoo' })
  end
end
