class DailySyncWorker < ApplicationWorker
  def perform
    Team.active.pluck(:id).each { |id| SyncSlackTeamWorker.perform_async(id) }
  end
end
