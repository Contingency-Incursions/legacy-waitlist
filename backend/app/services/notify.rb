# frozen_string_literal: true

class Notify

  class << self

    def send_event(event_names, data)
      ActiveSupport::Notifications.instrument('sse_event', extra: {data: data, event_names: event_names}) rescue nil
    end

  end
end
