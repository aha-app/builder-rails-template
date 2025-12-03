# frozen_string_literal: true

module SignedCookiesHelper
  # Reads signed cookies set by your application
  # Returns the decrypted values, not the encrypted cookie strings
  #
  # Example:
  #   get login_path, params: { email: user.email, password: 'secret' }
  #   expect(signed_cookies[:session_id]).to eq(session.id)
  def signed_cookies
    ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash).signed
  end
end

RSpec.configure do |config|
  config.include SignedCookiesHelper, type: :request
end
