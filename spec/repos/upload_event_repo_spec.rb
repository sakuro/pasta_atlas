# frozen_string_literal: true

RSpec.describe PastaAtlas::Repos::UploadEventRepo, :db do
  let(:repo) { Hanami.app["repos.upload_event_repo"] }
  let(:upload) { Factory[:upload] }

  def stored_events = Hanami.app["relations.upload_events"].where(upload_id: upload.id).to_a

  describe "#create" do
    it "stores the event with the database time when occurred_at is omitted" do
      repo.create(upload_id: upload.id, event_type: "pending")

      expect(stored_events).to contain_exactly(include(event_type: "pending", occurred_at: be_within(5).of(Time.now)))
    end

    it "stores the given occurred_at" do
      occurred_at = Time.at(Time.now.to_i - 3600)

      repo.create(upload_id: upload.id, event_type: "complete", occurred_at:)

      expect(stored_events).to contain_exactly(include(event_type: "complete", occurred_at:))
    end
  end
end
