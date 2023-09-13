# frozen_string_literal: true

module Langchain::Agent
  module RestGPTAgent
    class Main
      attr_accessor :llm, :api_spec, :planner, :api_selector, :scenario, :requests_wrapper, :simple_parser, :return_intermediate_steps, :max_iterations, :max_execution_time, :early_stopping_method, :callback_manager

      def initialize(
        llm, api_spec, scenario, requests_wrapper, caller_doc_with_response: false, parser_with_example: false, 
        simple_parser: false, callback_manager: nil, **kwargs
      )
        @llm = llm
        @api_spec = api_spec
        @scenario = case scenario.downcase
                    when 'tmdb', 'spotify' then scenario.downcase
                    else raise StandardError, "Invalid scenario #{scenario}"
                    end
        @requests_wrapper = requests_wrapper
        @simple_parser = simple_parser
        @return_intermediate_steps = kwargs[:return_intermediate_steps] || false
        @max_iterations = kwargs[:max_iterations] || 15
        @max_execution_time = kwargs[:max_execution_time]
        @early_stopping_method = kwargs[:early_stopping_method] || "force"
        @callback_manager = callback_manager

        @planner = Planner.new(llm: llm, scenario: @scenario)
        @api_selector = APISelector.new(llm: llm, scenario: @scenario, api_spec: api_spec)
      end

      def input_keys
        ["query"]
      end

      def output_keys
        @planner.output_keys
      end

      def debug_input
        puts "Debug..."
        gets.chomp
      end

      def _should_continue(iterations, time_elapsed)
        return false if @max_iterations && iterations >= @max_iterations
        return false if @max_execution_time && time_elapsed >= @max_execution_time

        true
      end

      def _return(output, intermediate_steps)
        @callback_manager.on_agent_finish(output, color: "green", verbose: @verbose) if @callback_manager
        final_output = output.return_values
        final_output["intermediate_steps"] = intermediate_steps if @return_intermediate_steps
        final_output
      end

      def _get_api_selector_background(planner_history)
        return "No background" if planner_history.empty?

        planner_history.map { |step| step[1] }.join("\n")
      end

      def _should_continue_plan(plan)
        !!(plan =~ /Continue/)
      end

      def _should_end(plan)
        !!(plan =~ /Final Answer/)
      end

      def call(inputs, run_manager: nil)
        query = inputs['query']

        planner_history = []
        iterations = 0
        time_elapsed = 0.0
        start_time = Time.now

        plan = @planner.call(input: query, history: planner_history)
        Langchain.logger.info("Planner: #{plan}")

        while _should_continue(iterations, time_elapsed)
          tmp_planner_history = [plan]
          api_selector_history = []
          api_selector_background = _get_api_selector_background(planner_history)
          api_plan = @api_selector.call(plan: plan, background: api_selector_background)

          finished = api_plan["result"].match(/No API call needed\.(.*)/)
          if finished.nil?
            executor = Caller.new(llm: @llm, api_spec: @api_spec, scenario: @scenario, simple_parser: @simple_parser, requests_wrapper: @requests_wrapper)
            execution_res = executor.call(api_plan: api_plan, background: api_selector_background)
          else
            execution_res = finished[1]
          end

          planner_history << [plan, execution_res]
          api_selector_history << [plan, api_plan, execution_res]

          plan = @planner.call(input: query, history: planner_history)
          Langchain.logger.info("Planner: #{plan}")

          while _should_continue_plan(plan)
            api_selector_background = _get_api_selector_background(planner_history)
            api_plan = @api_selector.call(plan: tmp_planner_history[0], background: api_selector_background, history: api_selector_history, instruction: plan)

            finished = api_plan.match(/No API call needed\.(.*)/)
            if finished.nil?
              executor = Caller.new(llm: @llm, api_spec: @api_spec, scenario: @scenario, simple_parser: @simple_parser, requests_wrapper: @requests_wrapper)
              execution_res = executor.call(api_plan: api_plan, background: api_selector_background)
            else
              execution_res = finished[1]
            end

            planner_history << [plan, execution_res]
            api_selector_history << [plan, api_plan, execution_res]

            plan = @planner.call(input: query, history: planner_history)
            Langchain.logger.info("Planner: #{plan}")
          end

          break if _should_end(plan)

          iterations += 1
          time_elapsed = Time.now - start_time
        end

        { "result" => plan }
      end
    end
  end
end
