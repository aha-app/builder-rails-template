# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

if Rails.env.development?
  require_relative "lib/vite_websocket_proxy"
  use ViteWebsocketProxy
end

run Rails.application
Rails.application.load_server
