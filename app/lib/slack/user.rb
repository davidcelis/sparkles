module Slack
  class User
    include ActiveModel::Model

    PUBLIC_ATTRIBUTES = %i[slack_team_id slack_id name username image_url deactivated]
    PRIVATE_ATTRIBUTES = %i[bot restricted].freeze
    attr_accessor *(PUBLIC_ATTRIBUTES + PRIVATE_ATTRIBUTES)

    alias_method :deactivated?, :deactivated
    alias_method :bot?, :bot
    alias_method :restricted?, :restricted

    def self.from_api_response(response)
      new(
        slack_team_id: response[:team_id],
        slack_id: response[:id],
        name: response[:profile][:real_name],
        username: response[:profile][:display_name],
        image_url: response[:profile][:image_512],
        deactivated: response[:deleted],
        bot: (response[:is_bot] || response[:id] == "USLACKBOT"),
        restricted: response[:is_restricted],
      )
    end

    def attributes
      Hash[PUBLIC_ATTRIBUTES.map { |attr| [attr, public_send(attr)] }]
    end

    def sparklebot?
      self.bot? && self.name == "Sparklebot"
    end

    def human_teammate?
      return false if bot? || restricted?

      true
    end
  end
end
