# frozen_string_literal: true

class SseController < ApplicationController
  include ActionController::Live

  def index
    request.env['rack.hijack'].call
    stream = request.env['rack.hijack_io']

    send_headers(stream)

    Thread.new do
      perform_task(stream)
    end

    response.close
  end

  private

  def perform_task(stream)
    sse = SSE.new(stream, retry: 300)

    sse.write('open', event: 'open')

    subscriber = ActiveSupport::Notifications.subscribe('sse_event') do |*args|
      # args includes information about the event
      # you can send this information back to the client as message
      begin
        args[4][:extra][:event_names].each do |event_name|
          sse.write(args[4][:extra][:data], event: event_name)
        end
      rescue IOError
        # client disconnected
      rescue ActionController::Live::ClientDisconnected
        sse.close
      ensure
        sse.close
      end


    end

    begin
      loop do
        # Heartbeat to keep the connection alive
        unless stream.closed?
          stream.write ":\n\n"
        end
        sleep 2
      end
    rescue IOError
      # client disconnected
    rescue ActionController::Live::ClientDisconnected
      sse.close
    ensure
      sse.close
    end
  ensure
    sse.close
  end

  def send_headers(stream)
    headers = [
      "HTTP/1.1 200 OK",
      "Content-Type: text/event-stream",
      "Cache-Control: no-transform"
    ]
    stream.write(headers.map { |header| header + "\r\n" }.join)
    stream.write("\r\n")
    stream.flush
  rescue
    stream.close
    raise
  end
end
