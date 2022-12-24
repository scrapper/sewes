require 'time'

require_relative '../lib/sewes'

RSpec.describe SEWeS::Cookie do
  describe 'Create and parse Cookies' do
    it 'should create a cookie' do
      cookie = SEWeS::Cookie.new('Animal', 'Lion')
      cookie.assign_flag('Secure')
      cookie.expires = Time.parse('2022-12-25-8:15 GMT')
      cookie.domain = 'kingdom.org'

      expect(cookie.to_escaped_s).to eql('Animal=Lion; Expires=Sun, 25 Dec 2022 08:15:00 GMT; Domain=kingdom.org; Secure')
    end

    it 'should parse a cookie' do
      cookie = SEWeS::Cookie.parse('Juwel=Ruby; Domain=ruby.org; SameSite=Lax; HttpOnly')
      expect(cookie).not_to be_nil
      expect(cookie.name).to eql('Juwel')
      expect(cookie.value).to eql('Ruby')
      expect(cookie.domain).to eql('ruby.org')
      expect(cookie.same_site).to eql('Lax')
      expect(cookie.http_only).to be true
    end
  end
end
