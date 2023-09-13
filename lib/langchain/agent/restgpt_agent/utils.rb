# frozen_string_literal: true

require "pry-byebug"

module Langchain::Agent
  module RestGPTAgent
    module Utils
      def get_matched_endpoint(api_spec, plan)
        pattern = /\b(GET|POST|PATCH|DELETE|PUT)\s+(\/\S+)*/
        matches = plan.scan(pattern)
        plan_endpoints = matches.map { |method, route| "#{method} #{route.split("?").first}" }

        spec_endpoints = api_spec.endpoints.map { |item| item[0] }

        matched_endpoints = []

        plan_endpoints.each do |plan_endpoint|
          if spec_endpoints.include?(plan_endpoint)
            matched_endpoints << plan_endpoint
            next
          end
          spec_endpoints.each do |name|
            arg_list = name.scan(/{(.*?)}/).flatten
            pattern = Regexp.new("^" + arg_list.reduce(name) { |acc, arg| acc.gsub("{#{arg}}", "[^/]+") } + "$")
            if pattern.match?(plan_endpoint)
              matched_endpoints << name
              break
            end
          end
        end

        return nil if matched_endpoints.empty?

        matched_endpoints
      end

      class ReducedOpenAPISpec
        attr_reader :servers, :description, :endpoints

        def initialize(servers:, description:, endpoints:)
          @servers = servers
          @description = description
          @endpoints = endpoints
        end
      end

      def reduce_endpoint_docs(docs)
        out = {}
        out['description'] = docs['description'] if docs['description']
        if docs['parameters']
          out['parameters'] = docs['parameters'].select { |parameter| parameter['required'] }
        end
        out['responses'] = docs['responses']['200'] if docs['responses'] && docs['responses']['200']
        out['requestBody'] = docs['requestBody'] if docs['requestBody']
        out
      end

      def reduce_openapi_spec(spec, dereference: true)
        # 1. Consider only get, post, patch, delete endpoints.
        endpoints = spec['paths'].flat_map do |route, operation|
          operation.select { |operation_name, _| %w[get post patch delete].include?(operation_name) }
                  .map { |operation_name, docs| ["#{operation_name.upcase} #{route}", docs['description'], docs] }
        end

        # 2. Replace any refs so that complete docs are retrieved.
        if dereference
          endpoints = endpoints.map do |name, description, docs|
            [name, description, dereference_refs(docs, full_schema: spec)]
          end
        end

        # 3. Strip docs down to required request args + happy path response.
        endpoints = endpoints.map do |name, description, docs|
          [name, description, reduce_endpoint_docs(docs)]
        end

        ReducedOpenAPISpec.new(
          servers: spec['servers'],
          description: spec['info']['description'] || '',
          endpoints: endpoints
        )
      end

      def retrieve_ref(path, schema)
        components = path.split("/")
        raise "ref paths are expected to be URI fragments, meaning they should start with #." if components[0] != "#"

        out = schema
        components[1..].each do |component|
          out = out[component]
        end
        Marshal.load(Marshal.dump(out))
      end

      def dereference_refs_helper(obj, full_schema, skip_keys)
        if obj.is_a?(Hash)
          obj_out = {}
          obj.each do |k, v|
            if skip_keys.include?(k)
              obj_out[k] = v
            elsif k == "$ref"
              ref = retrieve_ref(v, full_schema)
              return dereference_refs_helper(ref, full_schema, skip_keys)
            elsif v.is_a?(Array) || v.is_a?(Hash)
              obj_out[k] = dereference_refs_helper(v, full_schema, skip_keys)
            else
              obj_out[k] = v
            end
          end
          obj_out
        elsif obj.is_a?(Array)
          obj.map { |el| dereference_refs_helper(el, full_schema, skip_keys) }
        else
          obj
        end
      end

      def infer_skip_keys(obj, full_schema)
        keys = []
        if obj.is_a?(Hash)
          obj.each do |k, v|
            if k == "$ref"
              ref = retrieve_ref(v, full_schema)
              keys << v.split("/")[1]
              keys += infer_skip_keys(ref, full_schema)
            elsif v.is_a?(Array) || v.is_a?(Hash)
              keys += infer_skip_keys(v, full_schema)
            end
          end
        elsif obj.is_a?(Array)
          obj.each do |el|
            keys += infer_skip_keys(el, full_schema)
          end
        end
        keys
      end

      def dereference_refs(schema_obj, full_schema: nil, skip_keys: nil)
        full_schema ||= schema_obj
        skip_keys ||= infer_skip_keys(schema_obj, full_schema)
        dereference_refs_helper(schema_obj, full_schema, skip_keys)
      end

      def fix_json_error(data, return_str: true)
        data = data.strip.tr('"', '').tr(',', '').tr('`', '')

        begin
          JSON.parse(data)
          return data
        rescue JSON::ParserError
          data = data.split("\n").map(&:strip)
          data.each_with_index do |line, i|
            next if ['[', ']', '{', '}'].include?(line)
            next if ['[', ']', '{', '}'].any? { |char| line.end_with?(char) }

            unless line.end_with?(',') || [']', '}', '],', '},'].include?(data[i + 1])
              data[i] += ','
            end

            if [']', '}', '],', '},'].include?(data[i + 1]) && line.end_with?(',')
              data[i] = line[0..-2]
            end
          end
          data = data.join(' ')

          data = JSON.parse(data) unless return_str
          data
        end
      end
    end
  end
end
