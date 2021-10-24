module Slack
  class Team
    include ActiveModel::Model

    PUBLIC_ATTRIBUTES = %i[id name icon_url].freeze
    PRIVATE_ATTRIBUTES = [].freeze
    attr_accessor *(PUBLIC_ATTRIBUTES + PRIVATE_ATTRIBUTES)

    def self.from_api_response(response)
      new(
        id: response.id,
        name: response.name,
        icon_url: response.icon.image_original
      )
    end

    def attributes
      Hash[PUBLIC_ATTRIBUTES.map { |attr| [attr, public_send(attr)] }]
    end
  end
end
