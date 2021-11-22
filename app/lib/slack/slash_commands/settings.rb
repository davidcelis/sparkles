module Slack
  module SlashCommands
    class Settings
      FORMAT = /\Asettings\z/

      def self.execute(params)
        team = ::Team.find_by!(slack_id: params[:team_id])
        user = team.users.find_by!(slack_id: params[:user_id])
        view = {
          type: :modal,
          title: {
            type: :plain_text,
            text: "Configure Sparkles",
            emoji: true
          },
          submit: {
            type: :plain_text,
            text: ":sparkles: Submit",
            emoji: true
          },
          close: {
            type: :plain_text,
            text: ":x: Cancel",
            emoji: true
          },
          callback_id: "settings-#{team.slack_id}-#{user.slack_id}",
          blocks: [
            header_block(user),
            {type: :divider},
            user_leaderboard_block(user)
          ]
        }

        view[:blocks] += admin_blocks(team) if user.team_admin?

        team.api_client.views_open(trigger_id: params[:trigger_id], view: view)

        Result.new(response_type: nil)
      end

      private_class_method def self.header_block(user)
        {
          type: :section,
          text: {
            type: :mrkdwn,
            text: ":sparkles: Hi, <@#{user.slack_id}>! Here are some ways you can personalize your experience with Sparkles:"
          }
        }
      end

      private_class_method def self.user_leaderboard_block(user)
        block = {
          type: :section,
          text: {
            type: :mrkdwn,
            text: ":trophy: *Leaderboard settings*"
          },
          accessory: {
            type: :checkboxes,
            action_id: :user_leaderboard_enabled,
            options: [
              {
                text: {
                  type: :mrkdwn,
                  text: "*Enable the leaderboard*"
                },
                description: {
                  type: :mrkdwn,
                  text: "Disabling the leaderboard will hide point totals in most places, just for you! Others in your team will still see you in the leaderboard."
                },
                value: "true"
              }
            ]
          }
        }

        block[:accessory][:initial_options] = block[:accessory][:options].dup if user.leaderboard_enabled?

        block
      end

      private_class_method def self.admin_blocks(team)
        [
          {type: :divider},
          {
            type: :section,
            text: {
              type: :mrkdwn,
              text: ":lock: *Admin settings*"
            }
          },
          {
            type: :context,
            elements: [
              {
                type: :mrkdwn,
                text: "These settings will adjust the experience for everybody on your team."
              }
            ]
          },
          channel_block(team),
          team_leaderboard_block(team)
        ]
      end

      private_class_method def self.channel_block(team)
        block = {
          type: :section,
          text: {
            type: :mrkdwn,
            text: ":sparkle: *Sparkle Feed Channel*\nShare all sparkles as they're given!"
          },
          accessory: {
            type: :channels_select,
            action_id: :team_sparkle_feed_channel,
            placeholder: {
              type: :plain_text,
              text: "Channel",
              emoji: true
            }
          }
        }

        block[:accessory][:initial_channel] = team.slack_feed_channel_id if team.slack_feed_channel_id

        block
      end

      private_class_method def self.team_leaderboard_block(team)
        block = {
          type: :section,
          text: {
            type: :mrkdwn,
            text: ":trophy: *Leaderboard settings*"
          },
          accessory: {
            type: :checkboxes,
            action_id: :team_leaderboard_enabled,
            options: [
              {
                text: {
                  type: :mrkdwn,
                  text: "*Enable the leaderboard*"
                },
                description: {
                  type: :mrkdwn,
                  text: "Disabling the leaderboard will hide all sparkle point totals, with sparkles still visible via a team directory."
                },
                value: "true"
              }
            ]
          }
        }

        block[:accessory][:initial_options] = block[:accessory][:options].dup if team.leaderboard_enabled?

        block
      end
    end
  end
end
