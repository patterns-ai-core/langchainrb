# frozen_string_literal: true

RSpec.describe Langchain::Loader do
  describe "#load" do
    let(:status) { ["200", "OK"] }
    let(:body) { "Lorem Ipsum" }
    let(:content_type) { "text/plain" }
    let(:response) { double("response", status: status, read: body, content_type: content_type) }

    subject { described_class.new(path).load }

    before do
      allow(URI).to receive(:parse).and_return(double(open: response))
    end

    context "Text" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.txt" }

        it "loads text from file" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include("Lorem Ipsum")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.txt" }

        it "loads text from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to eq("Lorem Ipsum")
        end
      end
    end

    context "HTML" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.html" }

        it "loads text from file" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to eq("Lorem Ipsum\n\nDolor sit amet.")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.html" }
        let(:body) { "<html><body><h1>Lorem Ipsum</h1><p>Dolor sit amet.</p></body></html>" }
        let(:content_type) { "text/html" }

        it "loads text from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to eq("Lorem Ipsum\n\nDolor sit amet.")
        end
      end
    end

    context "PDF" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/cairo-unicode.pdf" }

        it "loads text from file" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include("UTF-8 encoded sample plain-text file")
          expect(subject.value).to include("The ASCII compatible UTF-8 encoding used in this plain-text file")
          expect(subject.value).to include("The Greek anthem:")
          expect(subject.value).to include("τελευτῆς ὁντινοῦν ποιεῖσθαι λόγον.")
          expect(subject.value).to include("Proverbs in the Amharic language")
          expect(subject.value).to include("ወዳጅህ ማር ቢሆን ጨርስህ አትላሰው።")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.pdf" }
        let(:body) { File.read("spec/fixtures/loaders/cairo-unicode.pdf") }
        let(:content_type) { "application/pdf" }

        it "loads text from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include("UTF-8 encoded sample plain-text file")
          expect(subject.value).to include("The ASCII compatible UTF-8 encoding used in this plain-text file")
          expect(subject.value).to include("The Greek anthem:")
          expect(subject.value).to include("τελευτῆς ὁντινοῦν ποιεῖσθαι λόγον.")
          expect(subject.value).to include("Proverbs in the Amharic language")
          expect(subject.value).to include("ወዳጅህ ማር ቢሆን ጨርስህ አትላሰው።")
        end
      end
    end

    context "DOCX" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/sample.docx" }

        it "loads text from file" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac faucibus odio.")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/sample.docx" }
        let(:body) { File.read("spec/fixtures/loaders/sample.docx") }
        let(:content_type) { "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }

        it "loads text from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac faucibus odio.")
        end
      end
    end

    context "CSV" do
      let(:result) do
        [
          ["Username", "Identifier", "First name", "Last name"],
          ["booker12", "9012", "Rachel", "Booker"],
          ["grey07", "2070", "Laura", "Grey"],
          ["johnson81", "4081", "Craig", "Johnson"],
          ["jenkins46", "9346", "Mary", "Jenkins"],
          ["smith79", "5079", "Jamie", "Smith"]
        ]
      end

      context "from local file" do
        context "with default options" do
          let(:path) { "spec/fixtures/loaders/example.csv" }

          it "loads data from file" do
            expect(subject).to be_a(Langchain::Data)
            expect(subject.value).to eq(result)
          end
        end

        context "with custom options" do
          let(:path) { "spec/fixtures/loaders/semicolon_example.csv" }
          let(:options) { {col_sep: ";"} }

          subject { described_class.new(path, options).load }

          it "loads data from csv file separated by semicolon" do
            expect(subject).to be_a(Langchain::Data)
            expect(subject.value).to eq(result)
          end
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.csv" }
        let(:body) { File.read("spec/fixtures/loaders/example.csv") }
        let(:content_type) { "text/csv" }

        it "loads data from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to eq(result)
        end
      end
    end

    context "JSON" do
      let(:result) do
        {"name" => "Luke Skywalker", "height" => 172, "mass" => 77}
      end

      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.json" }

        it "loads text from file" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include(result)
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.json" }
        let(:content_type) { "application/json" }
        let(:body) { File.read("spec/fixtures/loaders/example.json") }

        it "loads text from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include(result)
        end
      end
    end

    context "JSONL" do
      let(:result) do
        [
          {"name" => "Luke Skywalker", "height" => "172", "mass" => "77"},
          {"name" => "C-3PO", "height" => "167", "mass" => "75"},
          {"name" => "R2-D2", "height" => "96", "mass" => "32"},
          {"name" => "Darth Vader", "height" => "202", "mass" => "136"},
          {"name" => "Leia Organa", "height" => "150", "mass" => "49"}
        ]
      end
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.jsonl" }

        it "loads text from file" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to eq(result)
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.jsonl" }
        let(:content_type) { "application/jsonlines" }
        let(:body) { File.read("spec/fixtures/loaders/example.jsonl") }

        it "loads text from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to eq(result)
        end
      end
    end

    context "Custom processor passed as block" do
      subject do
        described_class.new(path).load { |text| text.reverse }
      end

      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.txt" }

        it "returns data processed with custom processor" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to include("muspI meroL")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.txt" }

        it "loads text from URL" do
          expect(subject).to be_a(Langchain::Data)
          expect(subject.value).to eq("muspI meroL")
        end
      end
    end

    context "Unsupported file type" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.swf" }

        it "raises unknown format" do
          expect { subject }.to raise_error Langchain::Loader::UnknownFormatError
        end
      end

      context "from url" do
        let(:path) { "http://example.com/sample.swf" }
        let(:body) { "" }
        let(:content_type) { "application/vnd.swf" }

        it "raises unknown format" do
          expect { subject }.to raise_error Langchain::Loader::UnknownFormatError
        end
      end
    end
  end

  describe "#url?" do
    subject { described_class.new(path).url? }

    context "with relative unix path" do
      let(:path) { "./tmp/file.txt" }

      it { expect(subject).to be_falsey }
    end

    context "with absolute unix path" do
      let(:path) { "/users/tmp/file.txt" }

      it { expect(subject).to be_falsey }
    end

    context "with absolute window path" do
      let(:path) { 'C:\Program Files\file.txt' }

      it { expect(subject).to be_falsey }
    end

    context "with https URL" do
      let(:path) { "https://example.com/file.txt" }

      it { expect(subject).to be_truthy }
    end

    context "with http URL" do
      let(:path) { "http://example.com/file.txt" }

      it { expect(subject).to be_truthy }
    end

    context "with ftp URL" do
      let(:path) { "ftp://example.com/file.txt" }

      it { expect(subject).to be_truthy }
    end
  end
end
