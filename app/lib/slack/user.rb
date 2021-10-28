module Slack
  class User
    include ActiveModel::Model

    PUBLIC_ATTRIBUTES = %i[slack_team_id slack_id name username image_url deactivated]
    PRIVATE_ATTRIBUTES = %i[bot].freeze
    attr_accessor *(PUBLIC_ATTRIBUTES + PRIVATE_ATTRIBUTES)

    alias_method :deactivated?, :deactivated
    alias_method :bot?, :bot

    def self.from_api_response(response)
      new(
        slack_team_id: response[:team_id],
        slack_id: response[:id],
        name: response[:profile][:real_name],
        username: response[:profile][:display_name],
        image_url: response[:profile][:image_512],
        deactivated: response[:deleted],
        bot: (response[:is_bot] || response[:id] == "USLACKBOT")
      )
    end

    def attributes
      Hash[PUBLIC_ATTRIBUTES.map { |attr| [attr, public_send(attr)] }]
    end

    def sparklebot?
      return false unless self.bot?

      self.name == "Sparklebot"
    end
  end
end
