# frozen_string_literal: true
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
  end
end
