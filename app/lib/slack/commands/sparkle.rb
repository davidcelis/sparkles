module Slack
  module Commands
    class Sparkle
      MULTI_USER_FORMAT = /\A(?<users>(?:#{Slack::Commands::USER_PATTERN}\s*,?\s*)+)(?:\s+(?<reason>.+))?\z/

      HELP_TEXT = <<~TEXT.strip
        Give someone a sparkle to show your appreciation! :sparkles:

        Usage: `/sparkle @user [reason]` or `/sparkle @user1, @user2, @user3 [reason]`

        Sparkles never need a reason, but if you want to include one and have it flow when read back later, it's best to start it with a reason with a coordinating conjunction (that's just a fancy way to say words like "for" or "because"). Have fun sparkling! :tada:
      TEXT

      def self.execute(params)
        text = params[:text].strip

        return {text: HELP_TEXT, response_type: :ephemeral} if text.strip == "help"

        match = text.match(MULTI_USER_FORMAT)

        unless match.present?
          return {
            text: "Sorry, I didn't understand that.\n\nUsage: `/sparkle @user [reason]` or `/sparkle @user1, @user2 [reason]`",
            response_type: :ephemeral
          }
        end

        # Extract all user IDs from the users string
        user_ids = match[:users].scan(Slack::Commands::USER_PATTERN).flatten

        # This is a bit of a hack to ensure that Sparklebot is a member of the
        # channel where the command was issued. This is necessary because we
        # can't send messages to channels where the bot isn't a member.
        team = Team.find(params[:team_id])
        scheduled_message = team.api_client.chat_scheduleMessage(channel: params[:channel_id], text: "Test!", post_at: 1.month.from_now.to_i)

        # Create a sparkle job for each user
        user_ids.each_with_index do |recipient_id, index|
          options = {
            team_id: params[:team_id],
            channel_id: params[:channel_id],
            user_id: params[:user_id],
            recipient_id: recipient_id,
            reason: match[:reason],
            response_url: params[:response_url],
            multi_sparkle: user_ids.length > 1
          }

          # Only pass scheduled_message_id to the last job for cleanup
          if index == user_ids.length - 1
            options[:scheduled_message_id] = scheduled_message[:scheduled_message_id]
          end

          SparkleJob.perform_later(options)
        end

        {response_type: :in_channel}
      rescue Slack::Web::Api::Errors::NotInChannel
        {
          text: "Oops! You'll need to `/invite` me to this channel before I can work here :sweat_smile: Here's that sparkle you tried to give away so you can copy and paste it back!\n\n/sparkle #{text}",
          response_type: :ephemeral
        }
      rescue Slack::Web::Api::Error => e
        Sentry.capture_exception(e)

        {
          text: "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I'll report this to my supervisor in the meantime. Here's that sparkle you tried to give away so you can try again more easily!\n\n/sparkle #{text}",
          response_type: :ephemeral
        }
      end
    end
  end
end
