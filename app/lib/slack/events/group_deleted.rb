module Slack
  module Events
    # The payloads are identical
    GroupDeleted = Class.new(ChannelDeleted)
  end
end
