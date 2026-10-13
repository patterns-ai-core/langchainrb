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
      response = subject.execute(input: "SELECT max(salary), count(*) FROM users")
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq([{salary: 23500, count: 101}])
    end

    it "returns jobs and counts of users" do
      response = subject.execute(input: "SELECT job, count(*) FROM users GROUP BY job")
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq([{job: "teacher", count: 5}, {job: "cook", count: 98}])
    end
  end

  describe "#dump_schema" do
    before do
      allow(subject.db).to receive(:tables).and_return([:users])
      allow(subject.db).to receive(:schema).with(:users).and_return([[:id, {type: :integer, primary_key: true}], [:name, {type: :string}], [:job, {type: :string}]])
      allow(subject.db).to receive(:foreign_key_list).with(:users).and_return([{columns: [:job], table: :jobs, key: [:job]}])
    end

    it "returns the schema" do
      response = subject.dump_schema
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq("CREATE TABLE users(\nid integer PRIMARY KEY,\nname string,\njob string,\nFOREIGN KEY (job) REFERENCES jobs(job));\n")
    end

    it "does not fail when key is not present" do
      allow(subject.db).to receive(:foreign_key_list).with(:users).and_return([{columns: [:job], table: :jobs, key: nil}])

      response = subject.dump_schema
      expect(response).to be_a(Langchain::ToolResponse)
      expect(response.content).to eq("CREATE TABLE users(\nid integer PRIMARY KEY,\nname string,\njob string,\nFOREIGN KEY (job) REFERENCES jobs());\n")
    end
  end

  context "with a real SQLite database" do
    subject { described_class.new(connection_string: "sqlite:/", tables: [:users, :memberships, :logs], exclude_tables: [:logs]) }

    before do
      subject.db.create_table(:users) do
        primary_key :id
        String :name
      end
      subject.db.create_table(:memberships) do
        Integer :user_id
        Integer :group_id
        String :role
        primary_key [:user_id, :group_id]
      end
      subject.db.create_table(:logs) { String :line }
      subject.db.create_table(:audits) { String :line }
    end

    it "lists only the requested tables, minus the excluded ones" do
      expect(subject.list_tables.content).to contain_exactly(:users, :memberships)
    end

    it "dumps the schema of those tables only" do
      expect(subject.dump_schema.content).to include("CREATE TABLE users(").and include("CREATE TABLE memberships(")
      expect(subject.dump_schema.content).not_to include("logs")
      expect(subject.dump_schema.content).not_to include("audits")
    end

    it "lists every table but the excluded ones when no tables are requested" do
      tool = described_class.new(connection_string: "sqlite:/", exclude_tables: [:logs])
      allow(tool).to receive(:db).and_return(subject.db)

      expect(tool.list_tables.content).to contain_exactly(:users, :memberships, :audits)
    end

    it "names the primary key columns of a composite key" do
      expect(subject.describe_tables(tables: [:memberships]).content).to eq(
        "CREATE TABLE memberships(\nuser_id integer,\ngroup_id integer,\nrole string,\nPRIMARY KEY (user_id,group_id));\n"
      )
    end

    it "leaves no trailing comma for a table without a primary key" do
      expect(subject.describe_tables(tables: [:logs]).content).to eq("CREATE TABLE logs(\nline string);\n")
    end
  end
end
