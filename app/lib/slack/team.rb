module Slack
  class Team
    include ActiveModel::Model

    PUBLIC_ATTRIBUTES = %i[slack_id name icon_url].freeze
    PRIVATE_ATTRIBUTES = [].freeze
    attr_accessor(*(PUBLIC_ATTRIBUTES + PRIVATE_ATTRIBUTES))

    def self.from_api_response(response)
      new(
        slack_id: response[:id],
        name: response[:name],
        icon_url: response.dig(:icon, :image_original)
      )
    end

    def attributes
      PUBLIC_ATTRIBUTES.map { |attr| [attr, public_send(attr)] }.to_h
    end
  end
end
