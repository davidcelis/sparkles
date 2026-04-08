module Slack
  module Commands
    class Remind
      DAYS_MAP = {
        "sunday" => 0, "sun" => 0,
        "monday" => 1, "mon" => 1,
        "tuesday" => 2, "tue" => 2,
        "wednesday" => 3, "wed" => 3,
        "thursday" => 4, "thu" => 4,
        "friday" => 5, "fri" => 5,
        "saturday" => 6, "sat" => 6
      }.freeze

      HELP_TEXT = <<~TEXT.strip
        Set up a recurring reminder to sparkle someone! :alarm_clock:

        *Set a reminder:*
        `/sparkles remind monday 9:00` — Reminds you every Monday at 9:00 AM ET
        `/sparkles remind friday 14:30` — Reminds you every Friday at 2:30 PM ET

        *Manage reminders:*
        `/sparkles remind list` — See your active reminders
        `/sparkles remind stop` — Remove all your reminders

        Times are in 24-hour format and default to America/New_York timezone.
      TEXT

      FORMAT = /\A(?<day>\w+)\s+(?<time>\d{1,2}:\d{2})\z/

      def self.execute(params)
        text = params[:text].to_s.sub(/\Aremind\s*/, "").strip
        team = Team.find(params[:team_id])

        return {text: HELP_TEXT, response_type: :ephemeral} if text.blank? || text == "help"
        return list_reminders(team, params) if text == "list"
        return stop_reminders(team, params) if text == "stop"

        match = text.match(FORMAT)
        unless match
          return {text: "Sorry, I didn't understand that.\n\n#{HELP_TEXT}", response_type: :ephemeral}
        end

        day_name = match[:day].downcase
        day_of_week = DAYS_MAP[day_name]
        unless day_of_week
          return {text: "I don't recognize \"#{match[:day]}\" as a day of the week. Try something like `monday` or `fri`.", response_type: :ephemeral}
        end

        time_of_day = match[:time]
        time_of_day = "0#{time_of_day}" if time_of_day.length == 4 # "9:00" -> "09:00"
        unless time_of_day.match?(/\A([01]\d|2[0-3]):[0-5]\d\z/)
          return {text: "That doesn't look like a valid time. Use 24-hour format like `9:00` or `14:30`.", response_type: :ephemeral}
        end

        reminder = team.sparkle_reminders.find_or_initialize_by(
          user_id: params[:user_id],
          day_of_week: day_of_week,
          time_of_day: time_of_day
        )
        reminder.active = true
        reminder.save!

        day_display = SparkleReminder::DAYS[day_of_week]
        {
          text: ":white_check_mark: Got it! I'll remind you to sparkle someone every #{day_display} at #{time_of_day}. :sparkles:",
          response_type: :ephemeral
        }
      end

      def self.list_reminders(team, params)
        reminders = team.sparkle_reminders.where(user_id: params[:user_id], active: true).order(:day_of_week, :time_of_day)

        if reminders.empty?
          return {text: "You don't have any sparkle reminders set up yet! Try `/sparkles remind monday 9:00` to get started.", response_type: :ephemeral}
        end

        lines = reminders.map { |r| "• Every #{r.day_name} at #{r.time_of_day} (#{r.timezone})" }
        {
          text: ":alarm_clock: *Your sparkle reminders:*\n#{lines.join("\n")}",
          response_type: :ephemeral
        }
      end

      def self.stop_reminders(team, params)
        count = team.sparkle_reminders.where(user_id: params[:user_id], active: true).update_all(active: false)

        if count == 0
          return {text: "You don't have any active reminders to stop!", response_type: :ephemeral}
        end

        {
          text: ":white_check_mark: Removed #{count} sparkle #{"reminder".pluralize(count)}. You can always set new ones with `/sparkles remind`!",
          response_type: :ephemeral
        }
      end
    end
  end
end
