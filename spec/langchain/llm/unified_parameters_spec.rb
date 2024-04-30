# frozen_string_literal: true

RSpec.describe Langchain::LLM::UnifiedParameters do
  # For now, the unifier only maps keys, but in the future it may be beneficial
  # to introduce an ActiveModel-style validator to restrict inputs to conform to
  # types required of the LLMs APIs
  let(:schema) do
    {beep: {defaults: "beep"}, boop: {aliases: [:booop]}}
  end
  let(:subject) { described_class.new(schema: schema) }

  it "provides a Null object" do
    null_unified_params = described_class::Null.new
    expect(null_unified_params).to be_kind_of(described_class)
    expect(null_unified_params.to_params(beep: 1, boop: 2, bop: 3)).to eq({})
    expect(null_unified_params.to_h).to eq({})
  end

  describe "#to_params" do
    let(:params) do
      {beep: 1, boop: 2, bop: 3}
    end

    it "filters out params not in the schema" do
      expect(subject.to_params(params)).to match(beep: 1, boop: 2)
    end

    context "with aliases" do
      let(:params) do
        {beep: 1, booop: 4, bop: 3}
      end
      it "translates alias schema fields" do
        expect(subject.to_params(params)).to match(beep: 1, boop: 4)
      end
    end

    context "with alias conflicts" do
      let(:params) do
        {beep: 1, boop: 2, bop: 3, booop: 4}
      end
      it "favors explicit params over aliases" do
        expect(subject.to_params(params)).to match(beep: 1, boop: 2)
      end
    end

    context "with ignored fields" do
      let(:params) do
        {beep: 1, boop: 2, bop: 3, booop: 4}
      end
      it "favors explicit params over aliases" do
        subject.update(bop: {})
        subject.ignore(:boop, :bop)
        expect(subject.to_params(params)).to match(beep: 1)
      end
    end
  end

  describe "#to_h" do
    let(:subject) do
      described_class.new(
        schema: schema,
        parameters: {beep: 1, boop: 2, bop: 3}
      )
    end
    it "aliases to_params" do
      expect(subject.to_h).to match(beep: 1, boop: 2)
    end
  end

  describe "#update(amended_schema)" do
    let(:subject) do
      described_class.new(schema: schema)
    end

    it "adds the additional fields to the schema" do
      instance = described_class.new(schema: schema)
      result = instance.update(
        beep: {default: "beepy"},
        boop: {defaults: "boops"},
        bop: {}
      )
      expect(result).to be_instance_of(described_class)
      expect(instance.schema.keys).to contain_exactly(:beep, :boop, :bop)
      expect(instance.to_params({bop: 3})).to match(
        beep: "beepy",
        boop: "boops",
        bop: 3
      )
    end

    it "allows amending schema and adding additional aliases" do
      result = subject.update(
        beep: {},
        boop: {aliases: [:bopity]},
        bop: {}
      )
      expect(result).to be_instance_of(described_class)
      expect(subject.schema.keys).to contain_exactly(:beep, :boop, :bop)
      expect(subject.to_params({beep: 1, boop: 2, bop: 3})).to match(
        beep: 1,
        boop: 2,
        bop: 3
      )
    end
  end

  describe "#alias_field(field, as:)" do
    it "adds any additional aliases" do
      subject.alias_field(:boop, as: :bopity)
      expect(subject.to_params({beep: 1, bopity: 2, bop: 3})).to match(
        beep: 1,
        boop: 2
      )
    end

    it "doesn't duplicate aliases" do
      subject.alias_field(:boop, as: :bopity)
      subject.alias_field(:boop, as: :bopity)
      expect(subject.aliases[:boop]).to match([
        :booop,
        :bopity
      ])
    end
  end
end
