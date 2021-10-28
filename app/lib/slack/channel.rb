module Slack
  class Channel
    include ActiveModel::Model

    PUBLIC_ATTRIBUTES = %i[slack_team_id slack_id name private archived].freeze
    PRIVATE_ATTRIBUTES = %i[shared].freeze
    attr_accessor *(PUBLIC_ATTRIBUTES + PRIVATE_ATTRIBUTES)

    alias_method :private?, :private
    alias_method :archived?, :archived
    alias_method :shared?, :shared

    def self.from_api_response(response)
      new(
        slack_team_id: Array(response[:shared_team_ids]).first,
        slack_id: response[:id],
        name: response[:name],
        private: response[:is_private],
        shared: response[:is_shared],
        archived: response[:is_archived],
      )
    end

    def attributes
      Hash[PUBLIC_ATTRIBUTES.map { |attr| [attr, public_send(attr)] }]
    end
  end
end
