# frozen_string_literal: true

module SignedCookiesHelper
  def signed_cookies
    cookies_hash = {}

    cookies.instance_variable_get(:@cookies).each do |cookie|
      value = cookie.value
      # Decode signed cookies using Rails' message verifier
      decoded_value = begin
        Rails.application.message_verifier(:cookies).verify(value)
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        value # Return raw value if not signed
      end

      cookies_hash[cookie.name.to_sym] = decoded_value
    end

    cookies_hash
  end
end

RSpec.configure do |config|
  config.include SignedCookiesHelper, type: :request
end
