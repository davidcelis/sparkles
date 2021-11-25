require "rails_helper"

RSpec.describe Slack::SlashCommands::Help do
  it "responds with usage text" do
    result = Slack::SlashCommands::Help.execute({})

    expect(result.response_type).to eq(:ephemeral)
    expect(result.text).to include("Welcome to Sparkles! I'd be happy to get you started :sparkles:")
    expect(result.text).to include(Slack::SlashCommands::Help::TEXT)
  end
end
