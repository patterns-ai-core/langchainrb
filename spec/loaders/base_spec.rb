# frozen_string_literal: true

RSpec.describe Loaders::Base do
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
          expect(subject).to include("Lorem Ipsum")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.txt" }

        it "loads text from URL" do
          expect(subject).to eq("Lorem Ipsum")
        end
      end
    end

    context "HTML" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.html" }

        it "loads text from file" do
          expect(subject).to eq("Lorem Ipsum\n\nDolor sit amet.")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.html" }
        let(:body) { "<html><body><h1>Lorem Ipsum</h1><p>Dolor sit amet.</p></body></html>" }
        let(:content_type) { "text/html" }

        it "loads text from URL" do
          expect(subject).to eq("Lorem Ipsum\n\nDolor sit amet.")
        end
      end
    end

    context "PDF" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/cairo-unicode.pdf" }

        it "loads text from file" do
          expect(subject).to include("UTF-8 encoded sample plain-text file")
          expect(subject).to include("The ASCII compatible UTF-8 encoding used in this plain-text file")
          expect(subject).to include("The Greek anthem:")
          expect(subject).to include("τελευτῆς ὁντινοῦν ποιεῖσθαι λόγον.")
          expect(subject).to include("Proverbs in the Amharic language")
          expect(subject).to include("ወዳጅህ ማር ቢሆን ጨርስህ አትላሰው።")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/example.pdf" }
        let(:body) { File.read("spec/fixtures/loaders/cairo-unicode.pdf") }
        let(:content_type) { "application/pdf" }

        it "loads text from URL" do
          expect(subject).to include("UTF-8 encoded sample plain-text file")
          expect(subject).to include("The ASCII compatible UTF-8 encoding used in this plain-text file")
          expect(subject).to include("The Greek anthem:")
          expect(subject).to include("τελευτῆς ὁντινοῦν ποιεῖσθαι λόγον.")
          expect(subject).to include("Proverbs in the Amharic language")
          expect(subject).to include("ወዳጅህ ማር ቢሆን ጨርስህ አትላሰው።")
        end
      end
    end

    context "DOCX" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/sample.docx" }

        it "loads text from file" do
          expect(subject).to include("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac faucibus odio.")
        end
      end

      context "from url" do
        let(:path) { "http://example.com/sample.docx" }
        let(:body) { File.read("spec/fixtures/loaders/sample.docx") }
        let(:content_type) { "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }

        it "loads text from URL" do
          expect(subject).to include("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc ac faucibus odio.")
        end
      end
    end

    context "Unsupported file type" do
      context "from local file" do
        let(:path) { "spec/fixtures/loaders/example.swf" }

        it "raises unknown format" do
          expect { subject }.to raise_error Loaders::UnknownFormatError
        end
      end

      context "from url" do
        let(:path) { "http://example.com/sample.swf" }
        let(:body) { "" }
        let(:content_type) { "application/vnd.swf" }

        it "raises unknown format" do
          expect { subject }.to raise_error Loaders::UnknownFormatError
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
