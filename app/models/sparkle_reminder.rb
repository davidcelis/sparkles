class SparkleReminder < ApplicationRecord
  belongs_to :team

  validates :user_id, presence: true
  validates :day_of_week, inclusion: {in: 0..6}
  validates :time_of_day, format: {with: /\A([01]\d|2[0-3]):[0-5]\d\z/}
  validates :timezone, presence: true

  DAYS = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  def day_name
    DAYS[day_of_week]
  end

  def due_now?
    now = Time.current.in_time_zone(timezone)
    now.wday == day_of_week && now.strftime("%H:%M") == time_of_day
  end
end
