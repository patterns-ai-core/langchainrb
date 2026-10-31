# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe Langchain::Tool::ParallelSearch do
  let(:endpoint) { "https://search.parallel.ai/mcp" }
  let(:user_agent) { "langchainrb-parallel-search/1.0" }
  let(:llm) { Langchain::LLM::OpenAI.new(api_key: "scripted-model-key") }

  before do
    @proxy_env = %w[http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy].to_h { |key| [key, ENV.delete(key)] }
    WebMock.enable!
    @webmock_config = %i[allow_net_connect allow_localhost allow].to_h { |key| [key, WebMock::Config.instance.public_send(key)] }
    WebMock.disable_net_connect!
    @requests = []
    @tool_result = {content: [{type: "text", text: "Source: https://example.test/source\nRuby release notes"}]}
    stub_request(:post, endpoint).to_return do |request|
      body = JSON.parse(request.body)
      @requests << {body: body, headers: request.headers, url: request.uri.to_s}
      result = case body["method"]
      when "initialize"
        {protocolVersion: "2025-03-26", capabilities: {tools: {}}, serverInfo: {name: "fixture", version: "1"}}
      when "tools/list"
        {tools: %w[web_search web_fetch].map { |name| {name: name, inputSchema: {type: "object", properties: {}}} }}
      when "tools/call"
        @on_call&.call(body)
        @tool_result
      end
      if body["id"]
        envelope = {jsonrpc: "2.0", id: body["id"], result: result}.to_json
        {status: 200, headers: {"Content-Type" => @sse ? "text/event-stream" : "application/json", "Mcp-Session-Id" => "http-fixture"}, body: @sse ? "event: message\ndata: #{envelope}\n\n" : envelope}
      else
        {status: 202, body: ""}
      end
    end
    stub_request(:delete, endpoint).to_return(status: 204)
  end

  after do
    WebMock.reset!
    @proxy_env.each { |key, value| ENV[key] = value if value }
    @webmock_config.each { |key, value| WebMock::Config.instance.public_send("#{key}=", value) }
  end

  # Scripted model turns use the real adapter, Assistant dispatcher, MCP SDK and
  # HTTP transport. No live LLM is involved.
  def drive(assistant, methods, extra_arguments: {}, tool_name: "langchain_tool_parallel_search")
    @sent = []
    queue = methods.dup
    allow(assistant.llm).to receive(:chat) do |**params|
      @sent << params
      method = queue.shift
      message = if method
        arguments = (method == "fetch") ? {urls: ["https://example.test/source"]} : {objective: "Find Ruby release notes", search_queries: ["recent Ruby release notes"]}
        arguments = {query: "Ruby releases"} if tool_name == "langchain_tool_tavily"
        {role: "assistant", tool_calls: [{id: "call-#{queue.length}", type: "function", function: {name: "#{tool_name}__#{method}", arguments: arguments.merge(extra_arguments).to_json}}]}
      else
        {role: "assistant", content: "Read https://example.test/source"}
      end
      Langchain::LLM::Response::OpenAIResponse.new({"choices" => [{"message" => JSON.parse(message.to_json)}], "usage" => {"prompt_tokens" => 1, "completion_tokens" => 1, "total_tokens" => 2}})
    end
    assistant.add_message_and_run!(content: "Research Ruby releases")
  end

  def calls
    @requests.select { |request| request[:body]["method"] == "tools/call" }
  end

  def session_ids
    calls.map { |request| request[:body].dig("params", "arguments", "session_id") }
  end

  it "resolves omitted tools through discovery/search/fetch and consumes output in the next model turn" do
    assistant = Langchain::Assistant.new(llm: llm)
    expect(assistant.tools.first).to be_a(described_class)
    expect(@requests).to be_empty
    drive(assistant, %w[search fetch])
    expect(assistant.state).to eq(:completed)
    expect(@sent.last[:messages].count { |message| message[:role] == "tool" }).to eq(2)
    expect(@sent.last[:messages].select { |message| message[:role] == "tool" }.map { |message| message[:content].to_s }).to all(include("https://example.test/source"))
    expect(calls.map { |request| request[:body].dig("params", "name") }).to eq(%w[web_search web_fetch])
    expect(@requests.map { |request| request[:body]["method"] }).to include("initialize", "tools/list", "tools/call")
    expect(@requests.map { |request| request[:headers]["User-Agent"] }).to all(eq(user_agent))
    expect(@requests.map { |request| request[:headers]["Authorization"] }).to all(be_nil)
    expect(@requests.map { |request| URI(request[:url]) }).to all(have_attributes(scheme: "https", host: "search.parallel.ai", port: 443, path: "/mcp", query: nil))
    expect(session_ids.uniq.size).to eq(1)
    expect(session_ids.first).to match(/\A[0-9a-f-]{36}\z/)
    expect(a_request(:delete, endpoint).with(headers: {"User-Agent" => user_agent})).to have_been_made.twice
  end

  it "preserves explicit arrays, empty disable controls, nil rejection and tool_choice none" do
    expect(Langchain::Assistant.new(llm: llm, tools: []).tools).to eq([])
    expect(Langchain::Assistant.new(llm: llm, tool_choice: "none").tools).to eq([])
    expect { Langchain::Assistant.new(llm: llm, tools: nil) }.to raise_error(ArgumentError)
    explicit = [Langchain::Tool::Tavily.new(api_key: "configured-choice")]
    assistant = Langchain::Assistant.new(llm: llm, tools: explicit)
    expect(assistant.tools).to equal(explicit)
    assistant.tools = []
    expect(assistant.tools).to eq([])
    expect(@requests).to be_empty
  end

  it "retains manual execution and callbacks" do
    assistant = Langchain::Assistant.new(llm: llm, tool_execution_callback: ->(*args) { @callback = args })
    response = {"choices" => [{"message" => {"role" => "assistant", "tool_calls" => [{"id" => "manual", "function" => {"name" => "langchain_tool_parallel_search__search", "arguments" => {objective: "Ruby", search_queries: ["Ruby release notes"]}.to_json}}]}}]}
    allow(llm).to receive(:chat).and_return(Langchain::LLM::Response::OpenAIResponse.new(response))
    assistant.add_message(content: "Search Ruby")
    assistant.run
    expect(assistant.state).to eq(:requires_action)
    expect(@requests).to be_empty
    expect(@callback).to be_nil
    assistant.send(:run_tool, assistant.messages.last.tool_calls.first)
    expect(@callback.first).to eq("manual")
    expect(calls.size).to eq(1)
  end

  it "retains IDs for follow-ups/system changes and renews them on clear or message replacement" do
    assistant = Langchain::Assistant.new(llm: llm)
    drive(assistant, %w[search fetch])
    first = session_ids.first
    assistant.instructions = "Updated instructions"
    drive(assistant, ["search"])
    expect(session_ids).to all(eq(first))
    expect { assistant.messages = ["invalid"] }.to raise_error(ArgumentError)
    drive(assistant, ["fetch"])
    expect(session_ids.last).to eq(first)
    assistant.clear_messages!
    drive(assistant, ["search"])
    expect(session_ids.last).not_to eq(first)
    second = session_ids.last
    replacement = []
    expect(assistant.public_send(:messages=, replacement)).to equal(replacement)
    expect(assistant.messages).to equal(replacement)
    drive(assistant, ["fetch"])
    expect(session_ids.last).not_to eq(second)
  end

  it "isolates interleaved conversations sharing one tool" do
    shared = described_class.new
    a = Langchain::Assistant.new(llm: llm, tools: [shared])
    b = Langchain::Assistant.new(llm: Langchain::LLM::OpenAI.new(api_key: "second-scripted-key"), tools: [shared])
    drive(a, ["search"])
    drive(b, ["search"])
    drive(a, ["fetch"])
    drive(b, ["fetch"])
    expect(session_ids[0]).to eq(session_ids[2])
    expect(session_ids[1]).to eq(session_ids[3])
    expect(session_ids[0]).not_to eq(session_ids[1])
  end

  it "isolates concurrent Assistants sharing one tool" do
    shared = described_class.new
    assistants = [llm, Langchain::LLM::OpenAI.new(api_key: "concurrent-scripted-key")].map { |model| Langchain::Assistant.new(llm: model, tools: [shared]) }
    mutex = Mutex.new
    ready = ConditionVariable.new
    count = 0
    @on_call = lambda do |body|
      next unless body.dig("params", "name") == "web_search"
      mutex.synchronize do
        count += 1
        (count == 2) ? ready.broadcast : ready.wait(mutex)
      end
    end
    threads = assistants.map { |assistant| Thread.new { drive(assistant, %w[search fetch]) } }
    threads.each(&:value)
    expect(assistants.map(&:state)).to all(eq(:completed))
    expect(session_ids.tally.values).to eq([2, 2])
  end

  it "retains configured provider failures without fallback" do
    stub_request(:post, "https://api.tavily.com/search").to_return(status: 401, body: '{"error":"configured key rejected"}')
    assistant = Langchain::Assistant.new(llm: llm, tools: [Langchain::Tool::Tavily.new(api_key: "configured-choice")])
    drive(assistant, ["search"], tool_name: "langchain_tool_tavily")
    expect(assistant.messages.find(&:tool?).content).to include("configured key rejected")
    expect(@requests).to be_empty
  end

  it "respects disabled selection and a permission callback even if a scripted model requests search" do
    assistant = Langchain::Assistant.new(llm: llm, tools: [described_class.new], tool_choice: "none")
    drive(assistant, ["search"])
    expect(assistant.state).to eq(:failed)
    permitted = Langchain::Assistant.new(llm: llm, tool_execution_callback: ->(*) { raise "permission denied" })
    drive(permitted, ["search"])
    expect(permitted.state).to eq(:failed)
    expect(@requests).to be_empty
  end

  it "overrides model-supplied identity and keeps it out of model schemas" do
    drive(Langchain::Assistant.new(llm: llm), ["search"], extra_arguments: {session_id: "model-supplied"})
    expect(session_ids.first).not_to eq("model-supplied")
    properties = described_class.function_schemas.to_openai_format.map { |schema| schema.dig(:function, :parameters, :properties) }
    expect(properties).to all(satisfy { |schema| !schema.key?(:session_id) })
  end

  it "returns quota errors without retrying or rotating IDs" do
    @tool_result = {isError: true, content: [{type: "text", text: "Anonymous free quota exceeded"}]}
    assistant = Langchain::Assistant.new(llm: llm)
    drive(assistant, ["search"])
    drive(assistant, ["fetch"])
    expect(session_ids.uniq.size).to eq(1)
    expect(calls.size).to eq(2)
    expect(assistant.messages.select(&:tool?).map(&:content)).to all(include("Parallel Search error: Anonymous free quota exceeded"))
  end

  it "handles SSE through the maintained HTTP transport" do
    @sse = true
    assistant = Langchain::Assistant.new(llm: llm)
    drive(assistant, %w[search fetch])
    expect(assistant.state).to eq(:completed)
    expect(calls.size).to eq(2)
  end

  it "returns HTTP and malformed-response errors as tool output" do
    stub_request(:post, endpoint).to_return(status: 503, body: "Unavailable")
    expect(described_class.new.search(objective: "Ruby", search_queries: ["Ruby releases"]).content).to include("Parallel Search error:")
    stub_request(:post, endpoint).to_return(status: 200, headers: {"Content-Type" => "application/json"}, body: "not-json")
    expect(described_class.new.search(objective: "Ruby", search_queries: ["Ruby releases"]).content).to include("Parallel Search error:")
  end

  it "bounds the total request and closes its HTTP session after timeout" do
    @on_call = ->(_) { sleep 1 }
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = described_class.new(timeout: 0.05).search(objective: "Ruby", search_queries: ["Ruby releases"])
    expect(result.content).to include("Parallel Search error:")
    expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 0.5
    expect(a_request(:delete, endpoint)).to have_been_made.once
  end

  it "bounds cleanup separately and retains a successful result when cleanup stalls" do
    stub_request(:delete, endpoint).to_return do
      sleep 1
      {status: 204}
    end
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = described_class.new(timeout: 0.05).search(objective: "Ruby", search_queries: ["Ruby releases"])
    expect(result.content).to include("https://example.test/source")
    expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 0.5
  end

  it "bounds incomplete SSE reconnection" do
    stub_request(:post, endpoint).to_return(status: 200, headers: {"Content-Type" => "text/event-stream"}, body: "id: keep\nretry: 5000\nevent: message\ndata: {}\n\n")
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = described_class.new(timeout: 0.05).search(objective: "Ruby", search_queries: ["Ruby releases"])
    expect(result.content).to include("Parallel Search error:")
    expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 0.5
  end

  it "propagates a caller-owned timeout instead of converting cancellation into tool output" do
    @on_call = ->(_) { sleep 1 }
    expect do
      Timeout.timeout(0.01) { described_class.new.search(objective: "Ruby", search_queries: ["Ruby releases"]) }
    end.to raise_error(Timeout::Error)
    expect(a_request(:delete, endpoint)).to have_been_made.once
  end

  it "propagates cancellation and closes its HTTP session" do
    @on_call = ->(_) { raise Interrupt, "cancel fixture" }
    expect { drive(Langchain::Assistant.new(llm: llm), ["search"]) }.to raise_error(Interrupt, "cancel fixture")
    expect(a_request(:delete, endpoint)).to have_been_made.once
  end

  it "rejects invalid queries, URLs, timeouts and unpublished methods before requests" do
    tool = described_class.new
    expect { tool.search(objective: "Ruby", search_queries: []) }.to raise_error(ArgumentError)
    expect { tool.fetch(urls: ["file:///etc/passwd"]) }.to raise_error(ArgumentError)
    expect { tool.fetch(urls: ["https://example.test"], objective: "x" * 201) }.to raise_error(ArgumentError)
    [0, -1, Float::INFINITY, "30"].each { |timeout| expect { described_class.new(timeout: timeout) }.to raise_error(ArgumentError) }
    assistant = Langchain::Assistant.new(llm: llm)
    call = {"id" => "invalid", "function" => {"name" => "langchain_tool_parallel_search__object_id", "arguments" => "{}"}}
    expect { assistant.send(:run_tool, call) }.to raise_error(ArgumentError, /Unknown ParallelSearch function/)
    expect(@requests).to be_empty
  end
end
