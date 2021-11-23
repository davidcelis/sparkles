module Slack
  class Channel
    include ActiveModel::Model

    PUBLIC_ATTRIBUTES = %i[slack_team_id slack_id name private archived shared read_only].freeze
    PRIVATE_ATTRIBUTES = [].freeze
    attr_accessor(*(PUBLIC_ATTRIBUTES + PRIVATE_ATTRIBUTES))

    alias_method :private?, :private
    alias_method :archived?, :archived
    alias_method :shared?, :shared
    alias_method :read_only?, :read_only

    def self.from_api_response(response, slack_team_id:)
      new(
        slack_team_id: slack_team_id,
        slack_id: response[:id],
        name: response[:name],
        private: response[:is_private],
        shared: !!(response[:is_shared] || response[:is_ext_shared] || response[:is_org_shared] || response[:is_pending_ext_shared]),
        archived: !!response[:is_archived],
        read_only: !!response[:is_read_only]
      )
    end

    def attributes
      PUBLIC_ATTRIBUTES.map { |attr| [attr, public_send(attr)] }.to_h
    end

    def sparklebot_should_join?
      return false if private? || shared? || archived? || read_only?

      true
    end
  end
end
