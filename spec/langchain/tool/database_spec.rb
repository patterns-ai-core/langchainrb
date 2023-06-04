# frozen_string_literal: true

require "sequel"

RSpec.describe Langchain::Tool::Database do
  subject {
    described_class.new("mock:///")
  }

  describe "#execute" do
    before do
      rows = []
      rows.push(salary: 23500, count: 101)
      rows2 = []
      rows2.push(job: "teacher", count: 5)
      rows2.push(job: "cook", count: 98)

      allow_any_instance_of(Sequel::Database).to receive(:[])
        .with("SELECT max(salary), count(*) FROM users")
        .and_return(rows)

      allow_any_instance_of(Sequel::Database).to receive(:[])
        .with("SELECT job, count(*) FROM users GROUP BY job")
        .and_return(rows2)
    end

    it "returns salary and count of users" do
      expect(subject.execute(input: "SELECT max(salary), count(*) FROM users")).to eq([{count: 101, salary: 23500}])
    end

    it "returns jobs and counts of users" do
      # TODO: Try returning a multi-line table result with a header
      expect(subject.execute(input: "SELECT job, count(*) FROM users GROUP BY job")).to eq([{count: 5, job: "teacher"}, {count: 98, job: "cook"}])
    end
  end
end
