module Slack
  class User
    include ActiveModel::Model

    PUBLIC_ATTRIBUTES = %i[slack_team_id slack_id name username image_url deactivated team_admin]
    PRIVATE_ATTRIBUTES = %i[bot restricted].freeze
    attr_accessor(*(PUBLIC_ATTRIBUTES + PRIVATE_ATTRIBUTES))

    alias_method :deactivated?, :deactivated
    alias_method :bot?, :bot
    alias_method :restricted?, :restricted
    alias_method :team_admin?, :team_admin

    def self.from_api_response(response)
      new(
        slack_team_id: response[:team_id],
        slack_id: response[:id],
        name: response.dig(:profile, :real_name),
        username: response.dig(:profile, :display_name),
        image_url: response.dig(:profile, :image_512),
        deactivated: !!response[:deleted],
        bot: !!(response[:is_bot] || response[:id] == "USLACKBOT"),
        restricted: !!(response[:is_restricted] || response[:is_ultra_restricted] || response[:is_stranger]),
        team_admin: !!(response[:is_admin] || response[:is_owner] || response[:is_primary_owner])
      )
    end

    def attributes
      PUBLIC_ATTRIBUTES.map { |attr| [attr, public_send(attr)] }.to_h
    end

    def sparklebot?
      bot? && name == "Sparklebot"
    end

    def human_teammate?
      return false if bot? || restricted?

      true
    end
  end
end
