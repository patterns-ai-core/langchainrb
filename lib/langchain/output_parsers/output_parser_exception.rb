class Langchain::OutputParsers::OutputParserException < StandardError
  def initialize(message, text)
    @message = message
    @text = text
  end

  def to_s
    "#{@message}\nText: #{@text}"
  end
end