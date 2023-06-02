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
end
