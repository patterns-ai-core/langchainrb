# frozen_string_literal: true

require "spec_helper"

RSpec.describe Langchain::Utils::ToBoolean do
  describe "#to_bool" do
    subject(:to_bool) { described_class.new.to_bool(value) }

    context "when Integer" do
      context "when 1" do
        let(:value) { 1 }

        it { is_expected.to eq true }
      end

      context "when 2" do
        let(:value) { 2 }

        it { is_expected.to eq false }
      end
    end

    context "when String" do
      context "when '1'" do
        let(:value) { "1" }

        it { is_expected.to eq true }
      end

      context "when 'true'" do
        let(:value) { "true" }

        it { is_expected.to eq true }
      end

      context "when 't'" do
        let(:value) { "t" }

        it { is_expected.to eq true }
      end

      context "when 'yes'" do
        let(:value) { "yes" }

        it { is_expected.to eq true }
      end

      context "when 'y'" do
        let(:value) { "y" }

        it { is_expected.to eq true }
      end

      context "when 'f'" do
        let(:value) { "f" }

        it { is_expected.to eq false }
      end

      context "when 'false'" do
        let(:value) { "false" }

        it { is_expected.to eq false }
      end
    end

    context "when Symbol" do
      context "when :1" do
        let(:value) { :"1" }

        it { is_expected.to eq true }
      end

      context "when :true" do
        let(:value) { :true }  # standard:disable Lint/BooleanSymbol

        it { is_expected.to eq true }
      end

      context "when :t" do
        let(:value) { :t }

        it { is_expected.to eq true }
      end

      context "when :yes" do
        let(:value) { :yes }

        it { is_expected.to eq true }
      end

      context "when :y" do
        let(:value) { :y }

        it { is_expected.to eq true }
      end

      context "when :f" do
        let(:value) { :f }

        it { is_expected.to eq false }
      end

      context "when :false" do
        let(:value) { :false } # standard:disable Lint/BooleanSymbol

        it { is_expected.to eq false }
      end
    end

    context "when TrueClass" do
      let(:value) { true }

      it { is_expected.to eq true }
    end

    context "when FalseClass" do
      let(:value) { false }

      it { is_expected.to eq false }
    end

    context "when nil" do
      let(:value) { nil }

      it { is_expected.to eq false }
    end

    context "when Float" do
      context "when 1.0" do
        let(:value) { 1.0 }

        it { is_expected.to eq false }
      end
    end

    context "when some other object" do
      let(:value) { described_class.new }

      it { is_expected.to eq false }
    end
  end
end
