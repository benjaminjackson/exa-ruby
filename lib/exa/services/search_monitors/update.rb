# frozen_string_literal: true

require_relative "../parameter_converter"
require_relative "../../resources/search_monitor"

module Exa
  module Services
    module SearchMonitors
      # PATCH /monitors/{id} — change part of a search monitor.
      # nil is sent as null only for the keys the API accepts as null (name, trigger,
      # metadata); trigger: nil removes the schedule. Other keys with nil are left out.
      class Update
        NULLABLE_KEYS = %i[name trigger metadata].freeze

        def initialize(connection, id:, **params)
          @connection = connection
          @id = id
          @params = params
        end

        def call
          response = @connection.patch("/monitors/#{@id}", request_body)
          Resources::SearchMonitor.from_response(response.body)
        end

        private

        def request_body
          @params.each_with_object({}) do |(key, value), body|
            next if value.nil? && !NULLABLE_KEYS.include?(key)

            case key
            when :search then body[:search] = ParameterConverter.convert(value)
            when :output_schema then body[:outputSchema] = value
            else body[key] = value
            end
          end
        end
      end
    end
  end
end
