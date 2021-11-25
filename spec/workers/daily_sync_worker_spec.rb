require "rails_helper"

RSpec.describe DailySyncWorker do
  it "queues a SyncSlackTeamWorker for each existing team" do
    teams = create_list(:team, 3)

    teams.each do |team|
      expect(SyncSlackTeamWorker).to receive(:perform_async).with(team.id)
    end

    DailySyncWorker.new.perform
  end
end
