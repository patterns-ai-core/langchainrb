# frozen_string_literal: true

require "sequel"

RSpec.describe Langchain::Tool::Database do
  subject { described_class.new(connection_string: "mock:///") }

  describe "#execute" do
    before do
      rows = []
      rows.push(salary: 23500, count: 101)
      rows2 = []
      rows2.push(job: "teacher", count: 5)
      rows2.push(job: "cook", count: 98)

      allow(subject.db).to receive(:[])
        .with("SELECT max(salary), count(*) FROM users")
        .and_return(rows)

      allow(subject.db).to receive(:[])
        .with("SELECT job, count(*) FROM users GROUP BY job")
        .and_return(rows2)
    end

    it "returns salary and count of users" do
      expect(subject.execute(input: "SELECT max(salary), count(*) FROM users")).to eq([{count: 101, salary: 23500}])
    end

    it "returns jobs and counts of users" do
      expect(subject.execute(input: "SELECT job, count(*) FROM users GROUP BY job")).to eq([{count: 5, job: "teacher"}, {count: 98, job: "cook"}])
    end
  end

  describe "#dump_schema" do
    before do
      allow(subject.db).to receive(:tables).and_return([:users])
      allow(subject.db).to receive(:schema).with(:users).and_return([[:id, {type: :integer, primary_key: true}], [:name, {type: :string}], [:job, {type: :string}]])
      allow(subject.db).to receive(:foreign_key_list).with(:users).and_return([{columns: [:job], table: :jobs, key: [:job]}])
    end

    it "returns the schema" do
      expect(subject.dump_schema).to eq("CREATE TABLE users(\nid integer PRIMARY KEY,\nname string,\njob string\n);\nALTER TABLE users ADD FOREIGN KEY (job) REFERENCES jobs(job);\n")
    end
  end
end
