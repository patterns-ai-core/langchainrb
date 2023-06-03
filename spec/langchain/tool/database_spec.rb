# frozen_string_literal: true

require "sequel"

RSpec.describe Langchain::Tool::Database do
  describe "#execute" do
    before do
      rows = []
      rows.push(salary: 23500, count: 101)

      allow_any_instance_of(Sequel::Database).to receive(:[])
        .with("SELECT max(salary), count(*) FROM users")
        .and_return(rows)
    end

    it "returns salary and count of users" do
      expect(subject.execute(input: "SELECT max(salary), count(*) FROM users")).to eq("salary: 23500, count: 101")
    end
  end

  describe "#schema" do
    before do
      allow_any_instance_of(Sequel::Database).to receive(:dump_schema_migration)
        .with(same_db: true, indexes: false)
        .and_return("example_schema_from_sequel")
    end

    xit "returns the schema and example rows" do
      # Implement this in a subsequent PR
      subject.schema.to.eq(<<~SCHEMA.chomp
        CREATE TABLE Highschooler(
          ID int primary key,
          name text,
          grade int)
          /*
          3 example rows:
          SELECT * FROM Highschooler LIMIT 3;
          ID name grade
          1510 Jordan 9
          1689 Gabriel 9
          1381 Tiffany 9
          */
          CREATE TABLE Friend(
          student_id int,
          friend_id int,
          primary key (student_id,friend_id),
          foreign key(student_id) references Highschooler(ID),
          foreign key (friend_id) references Highschooler(ID)
          )
          /*
          3 example rows:
          SELECT * FROM Friend LIMIT 3;
          student_id friend_id
          1510 1381
          1510 1689
          1689 1709
          */
      SCHEMA
                          )
    end
  end
end
