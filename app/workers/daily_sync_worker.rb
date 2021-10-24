class DailySyncWorker < ApplicationWorker
  def perform
    Team.pluck(:id).each { |id| SyncSlackTeamWorker.perform_async(id) }
  end
end
