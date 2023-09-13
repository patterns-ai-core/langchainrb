# frozen_string_literal: true

require "pry-byebug"

module Langchain::Agent
  module RestGPTAgent
    class Caller
      attr_accessor :llm, :api_spec, :scenario, :requests_wrapper, :max_iterations, :max_execution_time, :early_stopping_method, :simple_parser, :with_response, :output_key

      def initialize(llm:, api_spec:, scenario:, requests_wrapper:, simple_parser: false, with_response: false)
        @llm = llm
        @api_spec = api_spec
        @scenario = scenario
        @requests_wrapper = requests_wrapper
        @max_iterations = 15
        @max_execution_time = nil
        @early_stopping_method = "force"
        @simple_parser = simple_parser
        @with_response = with_response
        @output_key = "result"
      end

      def _should_continue(iterations, time_elapsed)
        return false if !@max_iterations.nil? && iterations >= @max_iterations
        return false if !@max_execution_time.nil? && time_elapsed >= @max_execution_time

        true
      end

      def observation_prefix
        "Response: "
      end

      def llm_prefix
        "Thought: "
      end

      def _stop
        [
          "\n#{observation_prefix.rstrip}",
          "\n\t#{observation_prefix.rstrip}",
        ]
      end

      def _construct_scratchpad(history)
        return "" if history.empty?

        scratchpad = ""
        history.each_with_index do |(plan, execution_res), i|
          scratchpad += "#{llm_prefix}#{i + 1}#{plan}\n"
          scratchpad += "#{observation_prefix}#{execution_res}\n"
        end
        scratchpad
      end

      def _get_action_and_input(llm_output)
        if llm_output.include?("Execution Result:")
          return ["Execution Result", llm_output.split("Execution Result:").last.strip]
        end

        regex = /Operation:[\s]*(.*?)[\n]*Input:[\s]*(.*)/m
        match = llm_output.match(regex)

        raise StandardError, "Could not parse LLM output: `#{llm_output}`" if match.nil?

        action = match[1].strip
        action_input = match[2]
        raise NotImplementedError if !["GET", "POST", "DELETE", "PUT"].include?(action)

        # action_input = fix_json_error(action_input)

        [action, action_input]
      end

      def _get_response(action, action_input)
        action_input = action_input.strip.chomp('`')
        left_bracket = action_input.index('{')
        right_bracket = action_input.rindex('}')
        action_input = action_input[left_bracket..right_bracket]

        data = JSON.parse(action_input)
        desc = data.fetch("description", "No description")
        query = data["output_instructions"]

        params, request_body, response = nil, nil, nil

        case action
        when "GET"
          params = data["params"] if data.key?("params")
          response = @requests_wrapper.get(data["url"], params)
        when "POST"
          params = data["params"]
          request_body = data["data"]
          response = @requests_wrapper.post(data["url"], params: params, data: request_body)
        when "PUT"
          params = data["params"]
          request_body = data["data"]
          response = @requests_wrapper.put(data["url"], params: params, data: request_body)
        when "DELETE"
          params = data["params"]
          request_body = data["data"]
          response = @requests_wrapper.delete(data["url"], params: params, json: request_body)
        else
          raise NotImplementedError
        end

        response_text = if response.is_a?(Faraday::Response)
                          response.status != 200 ? response.body : response.body
                        elsif response.is_a?(String)
                          response
                        else
                          raise NotImplementedError
                        end

        [response_text, params, request_body, desc, query]
      end

      def call(api_plan:, background:)
        iterations = 0
        time_elapsed = 0.0
        start_time = Time.now
        intermediate_steps = []

        api_url = @api_spec.servers[0]['url']
        matched_endpoints = get_matched_endpoint(@api_spec, api_plan["result"])
        endpoint_docs_by_name = Hash[@api_spec.endpoints.map { |x| [x[0], x[2]] }]
        api_doc_for_caller = ""
        raise "Found #{matched_endpoints.length} matched endpoints, but expected 1." if matched_endpoints.length != 1

        endpoint_name = matched_endpoints[0]
        tmp_docs = Marshal.load(Marshal.dump(endpoint_docs_by_name[endpoint_name]))
        if tmp_docs.key?('responses') && tmp_docs['responses'].key?('content')
          content = tmp_docs['responses']['content']
          tmp_docs['responses'] = content.key?('application/json') ? content['application/json']['schema']['properties'] : content['application/json; charset=utf-8']['schema']['properties']
        end
        tmp_docs.delete("responses") if !@with_response && tmp_docs.key?("responses")
        tmp_docs = YAML.dump(tmp_docs)
        encoder = Tiktoken.encoding_for_model('text-davinci-003')
        encoded_docs = encoder.encode(tmp_docs)
        tmp_docs = encoder.decode(encoded_docs[0...1500]) if encoded_docs.length > 1500
        api_doc_for_caller += "== Docs for #{endpoint_name} == \n#{tmp_docs}\n"

        while _should_continue(iterations, time_elapsed)
          scratchpad = _construct_scratchpad(intermediate_steps)

          caller_prompt = prompt_template.format(
            api_url: api_url,
            api_docs: api_doc_for_caller,
            api_plan: api_plan,
            background: background,
            agent_scratchpad: scratchpad
          )

          caller_chain_output = @llm.complete(prompt: caller_prompt, stop_sequences: _stop)

          Langchain.logger.info("Caller: #{caller_chain_output}")

          action, action_input = _get_action_and_input(caller_chain_output)
          if action == "Execution Result"
            return {"result" => action_input}
          end
          response, params, request_body, desc, query = _get_response(action, action_input)

          called_endpoint_name = action + ' ' + JSON.parse(action_input)['url'].gsub(api_url, '')
          called_endpoint_name = get_matched_endpoint(@api_spec, called_endpoint_name)[0]
          api_path = api_url + called_endpoint_name.split(' ').last
          api_doc_for_parser = endpoint_docs_by_name[called_endpoint_name]
          # ... (additional spotify specific code here)

          response_parser = if !@simple_parser
                              ResponseParser.new(
                                llm: @llm,
                                api_path: api_path,
                                api_doc: api_doc_for_parser,
                              )
                            else
                              SimpleResponseParser.new(
                                llm: @llm,
                                api_path: api_path,
                                api_doc: api_doc_for_parser,
                              )
                            end

          params_or_data = {
            "params" => params.nil? ? "No parameters" : params,
            "data" => request_body.nil? ? "No request body" : request_body,
          }
          parsing_res = response_parser.call(query: query, response_description: desc, api_param: params_or_data, json: response)
          Langchain.logger.info("Parser: #{parsing_res}")

          intermediate_steps.append([caller_chain_output, parsing_res])

          iterations += 1
          time_elapsed = Time.now - start_time
        end

        {"result" => caller_chain_output}
      end

      private

      def prompt_template
        @template ||= Langchain::Prompt.load_from_path(
          file_path: Langchain.root.join("langchain/agent/restgpt_agent/prompts/caller.yaml")
        )
      end
    end
  end
end
