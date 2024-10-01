module Langchain
  module Messages
    class AwsBedrockMessage < Base
      def initialize(role:, content: nil, tool_calls: [], tool_call_id: nil)
        @role = role
        @content = content
        @tool_calls = tool_calls
        @tool_call_id = tool_call_id
      end

      def to_h
        hash = {role: role}
        hash[:content] = content if content
        hash[:tool_calls] = tool_calls if tool_calls.any?
        hash[:tool_call_id] = tool_call_id if tool_call_id
        hash
      end

      def to_aws_bedrock_format
        case role
        when "system"
          {role: "system", content: content}
        when "human"
          {role: "user", content: content}
        when "ai"
          {role: "assistant", content: content, tool_calls: tool_calls}
        when "tool"
          {role: "tool", content: content, tool_call_id: tool_call_id}
        else
          raise ArgumentError, "Invalid role: #{role}"
        end
      end

      def self.from_aws_bedrock_format(message)
        role = case message[:role]
        when "system" then "system"
        when "user" then "human"
        when "assistant" then "ai"
        when "tool" then "tool"
        else
          raise ArgumentError, "Invalid role: #{message[:role]}"
        end

        new(
          role: role,
          content: message[:content],
          tool_calls: message[:tool_calls] || [],
          tool_call_id: message[:tool_call_id]
        )
      end
    end
  end
end
