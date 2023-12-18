# frozen_string_literal: true

class Notify

  class << self

    def send_event(event_names, data, sub_override: 'sse_event')
      ActiveSupport::Notifications.instrument(sub_override, extra: {data: data, event_names: event_names}) rescue nil
    end

  end
end
