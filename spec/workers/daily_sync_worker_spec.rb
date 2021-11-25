require "rails_helper"

RSpec.describe DailySyncWorker do
  it "queues a SyncSlackTeamWorker for each active team" do
    teams = create_list(:team, 3)
    teams.each do |team|
      expect(SyncSlackTeamWorker).to receive(:perform_async).with(team.id)
    end

    uninstalled_team = create(:team, uninstalled: true)
    expect(SyncSlackTeamWorker).not_to receive(:perform_async).with(uninstalled_team.id)

    DailySyncWorker.new.perform
  end
end
