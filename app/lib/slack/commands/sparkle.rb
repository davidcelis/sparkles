module Slack
  module Commands
    class Sparkle
      FORMAT = /\A#{Slack::Commands::USER_PATTERN}(\s+(?<reason>.+))?\z/

      HELP_TEXT = <<~TEXT.strip
        Give someone a sparkle to show your appreciation! :sparkles:

        Usage: `/sparkle @user [reason]`

        Sparkles never need a reason, but if you want to include one and have it flow when read back later, it’s best to start it with a reason with a coordinating conjunction (that’s just a fancy way to say words like “for” or “because”). Have fun sparkling! :tada:
      TEXT

      def self.execute(params)
        text = params[:text].strip

        return {text: HELP_TEXT, response_type: :ephemeral} if text.strip == "help"

        match = text.match(FORMAT)

        unless match.present?
          return {
            text: "Sorry, I didn’t understand that.\n\nUsage: `/sparkle @user [reason]`",
            response_type: :ephemeral
          }
        end

        # This is a bit of a hack to ensure that Sparklebot is a member of the
        # channel where the command was issued. This is necessary because we
        # can't send messages to channels where the bot isn't a member.
        team = Team.find(params[:team_id])
        scheduled_message = team.api_client.chat_scheduleMessage(channel: params[:channel_id], text: "Test!", post_at: 1.month.from_now.to_i)

        options = {
          team_id: params[:team_id],
          channel_id: params[:channel_id],
          user_id: params[:user_id],
          recipient_id: match[:user_id],
          reason: match[:reason],

          # We'll typically use the chat.postMessage method to respond to the
          # user, but if we run into a Slack error, we'll use the more reliable
          # response_url instead.
          response_url: params[:response_url],

          # Pass the scheduled message ID so we can delete it at the end.
          scheduled_message_id: scheduled_message[:scheduled_message_id]
        }

        SparkleJob.perform_later(options)

        {response_type: :in_channel}
      rescue Slack::Web::Api::Errors::NotInChannel
        {
          text: "Oops! You'll need to `/invite` me to this channel before I can work here :sweat_smile: Here’s that sparkle you tried to give away so you can copy and paste it back!\n\n/sparkle #{text}",
          response_type: :ephemeral
        }
      rescue Slack::Web::Api::Error => e
        Sentry.capture_exception(e)

        {
          text: "Oops, I ran into an unexpected problem with Slack :sweat: You can try again, and I’ll report this to my supervisor in the meantime. Here’s that sparkle you tried to give away so you can try again more easily!\n\n/sparkle #{text}",
          response_type: :ephemeral
        }
      end
    end
  end
end
