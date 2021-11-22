module FixtureSpecHelpers
  def event_fixture(event_type)
    path = Rails.root.join("spec", "fixtures", "slack", "events", "#{event_type}.json")

    JSON.parse(File.read(path)).with_indifferent_access
  end
end
