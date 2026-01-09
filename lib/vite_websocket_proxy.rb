require "socket"

class ViteWebsocketProxy
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["HTTP_UPGRADE"]&.downcase == "websocket" && env["PATH_INFO"]&.start_with?("/vite-dev/")
      proxy_websocket(env)
    else
      @app.call(env)
    end
  end

  private

  def proxy_websocket(env)
    vite_socket = Socket.tcp(ViteRuby.config.host, ViteRuby.config.port)
    vite_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

    path = env["PATH_INFO"]
    path += "?#{env["QUERY_STRING"]}" unless env["QUERY_STRING"].to_s.empty?

    request = "GET #{path} HTTP/1.1\r\n" \
              "Host: #{ViteRuby.config.host}:#{ViteRuby.config.port}\r\n" \
              "Upgrade: websocket\r\n" \
              "Connection: Upgrade\r\n" \
              "Sec-WebSocket-Key: #{env["HTTP_SEC_WEBSOCKET_KEY"]}\r\n" \
              "Sec-WebSocket-Version: #{env["HTTP_SEC_WEBSOCKET_VERSION"]}\r\n"
    request += "Sec-WebSocket-Protocol: #{env["HTTP_SEC_WEBSOCKET_PROTOCOL"]}\r\n" if env["HTTP_SEC_WEBSOCKET_PROTOCOL"]
    request += "\r\n"

    vite_socket.write(request)
    vite_socket.flush

    response = ""
    while (line = vite_socket.gets)
      response += line
      break if line == "\r\n"
    end

    return [ 502, {}, [ "Vite HMR connection failed" ] ] unless response.include?("101")

    env["rack.hijack"].call
    client = env["rack.hijack_io"]
    client.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
    client.write(response)
    client.flush

    Thread.new { stream(vite_socket, client) }
    Thread.new { stream(client, vite_socket) }

    [ -1, {}, [] ]
  rescue StandardError
    vite_socket&.close rescue nil
    [ 502, {}, [ "WebSocket proxy error" ] ]
  end

  def stream(from, to)
    IO.copy_stream(from, to)
  rescue IOError, Errno::ECONNRESET, Errno::EPIPE
    # closed
  ensure
    from.close rescue nil
    to.close rescue nil
  end
end
