class SparkleReminderJob < ApplicationJob
  queue_as :default

  PROMPTS = [
    "Hey there! :wave: It's sparkle time! Is there someone on your team who's been doing great work? Give them a sparkle with `/sparkle @someone`!",
    "Friendly reminder: a little recognition goes a long way! :sparkles: Who deserves a sparkle today?",
    "Time to spread some sparkle joy! :tada: Think of someone who made your day better and `/sparkle` them!",
    "Your sparkle reminder is here! :alarm_clock: Who's been crushing it lately? Let them know with `/sparkle @someone`!",
    "Don't forget to recognize your teammates! :sparkles: A quick `/sparkle @someone for being awesome` can really make someone's day.",
    "Sparkle check-in! :sparkle: Has anyone helped you out recently? Now's a great time to show some appreciation!",
    "Hey! Remember to celebrate your teammates. :raised_hands: Use `/sparkle @someone` to brighten their day!"
  ].freeze

  def perform
    # Find all active reminders that are due right now (within the current
    # minute window). We check each reminder's timezone to determine if
    # it's the right day and time.
    SparkleReminder.where(active: true).find_each do |reminder|
      next unless reminder.due_now?

      team = reminder.team
      next unless team.active?

      begin
        # Open a DM conversation with the user and send the reminder
        conversation = team.api_client.conversations_open(users: reminder.user_id)
        channel_id = conversation.channel.id

        team.api_client.chat_postMessage(
          channel: channel_id,
          text: PROMPTS.sample
        )
      rescue Slack::Web::Api::Errors::UserNotFound, Slack::Web::Api::Errors::CannotDmBot
        # User no longer exists or is a bot; deactivate the reminder
        reminder.update!(active: false)
      rescue Slack::Web::Api::Error => e
        Sentry.capture_exception(e)
      end
    end
  end
end
