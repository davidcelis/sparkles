require "rails_helper"

RSpec.describe SyncSlackTeamWorker do
  let(:team) { create(:team, :sparkles, name: "Old Sparkles") }

  subject(:worker) { SyncSlackTeamWorker.new.perform(team.id) }

  it "syncs all relevant data for a team" do
    expect {
      VCR.use_cassette("sync_slack_team") { worker }
    }.to change {
      User.count
    }.from(0).to(5).and change {
      Channel.count
    }.from(0).to(8)

    # Verify team information
    expect(team.reload.name).to eq("Sparkles")

    # Verify users
    david = team.users.find_by(slack_id: "U02JE49NDNY")
    expect(david.name).to eq("David Celis")
    expect(david.username).to eq("David")
    expect(david.image_url).to eq("https://secure.gravatar.com/avatar/66b085a6f16864adae78586e92811a73.jpg?s=512&d=https%3A%2F%2Fa.slack-edge.com%2Fdf10d%2Fimg%2Favatars%2Fava_0002-512.png")
    expect(david).not_to be_deactivated
    expect(david).to be_team_admin

    madeline = team.users.find_by(slack_id: "U02K7AUR7LN")
    expect(madeline.name).to eq("Madeline")
    expect(madeline.username).to eq("Madeline")
    expect(madeline.image_url).to eq("https://avatars.slack-edge.com/2021-11-06/2694805888659_48a663eb4df607b0a107_512.jpg")
    expect(madeline).not_to be_deactivated
    expect(madeline).not_to be_team_admin

    steven = team.users.find_by(slack_id: "U02KE361RNF")
    expect(steven.name).to eq("Steven")
    expect(steven.username).to eq("Steven")
    expect(steven.image_url).to eq("https://avatars.slack-edge.com/2021-11-06/2691816103877_424ca97395bf0c200ccc_512.jpg")
    expect(steven).not_to be_deactivated
    expect(steven).not_to be_team_admin

    henry = team.users.find_by(slack_id: "U02KG93ESUU")
    expect(henry.name).to eq("Henry")
    expect(henry.username).to eq("Henry")
    expect(henry.image_url).to eq("https://avatars.slack-edge.com/2021-11-06/2718481720432_46eba6ec0218d95a3a78_512.jpg")
    expect(henry).not_to be_deactivated
    expect(henry).not_to be_team_admin

    annabelle = team.users.find_by(slack_id: "U02JZCB1U5D")
    expect(annabelle.name).to eq("Annabelle")
    expect(annabelle.username).to eq("Annabelle")
    expect(annabelle.image_url).to eq("https://avatars.slack-edge.com/2021-11-06/2707404193729_7212dcae5c442f069a1f_512.jpg")
    expect(annabelle).not_to be_deactivated
    expect(annabelle).not_to be_team_admin

    # Verify channels
    general = team.channels.find_by(slack_id: "C02J565A4CE")
    expect(general.name).to eq("general")
    expect(general).not_to be_private
    expect(general).not_to be_shared
    expect(general).not_to be_archived
    expect(general).not_to be_read_only

    random = team.channels.find_by(slack_id: "C02JBTVC17D")
    expect(random.name).to eq("random")
    expect(random).not_to be_private
    expect(random).not_to be_shared
    expect(random).not_to be_archived
    expect(random).not_to be_read_only

    marketing = team.channels.find_by(slack_id: "C02LBQNLYG5")
    expect(marketing.name).to eq("marketing")
    expect(marketing).not_to be_private
    expect(marketing).not_to be_shared
    expect(marketing).not_to be_archived
    expect(marketing).not_to be_read_only

    sparkles = team.channels.find_by(slack_id: "C02LEQ0E1QS")
    expect(sparkles.name).to eq("sparkles")
    expect(sparkles).not_to be_private
    expect(sparkles).not_to be_shared
    expect(sparkles).not_to be_archived
    expect(sparkles).not_to be_read_only

    alerts = team.channels.find_by(slack_id: "C02LV0DAH8V")
    expect(alerts.name).to eq("alerts")
    expect(alerts).not_to be_private
    expect(alerts).not_to be_shared
    expect(alerts).not_to be_archived
    expect(alerts).not_to be_read_only

    support = team.channels.find_by(slack_id: "C02M4ES2LQ0")
    expect(support.name).to eq("support")
    expect(support).not_to be_private
    expect(support).not_to be_shared
    expect(support).not_to be_archived
    expect(support).not_to be_read_only

    engineering = team.channels.find_by(slack_id: "C02M4ESGYEL")
    expect(engineering.name).to eq("engineering")
    expect(engineering).not_to be_private
    expect(engineering).not_to be_shared
    expect(engineering).not_to be_archived
    expect(engineering).not_to be_read_only

    test = team.channels.find_by(slack_id: "C02NCMN16PQ")
    expect(test.name).to eq("test")
    expect(test).not_to be_private
    expect(test).not_to be_shared
    expect(test).not_to be_archived
    expect(test).not_to be_read_only
  end
end
