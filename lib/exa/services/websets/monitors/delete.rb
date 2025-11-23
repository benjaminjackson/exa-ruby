# frozen_string_literal: true

module Exa
  module Services
    module Websets
      module Monitors
        class Delete
          def initialize(connection, id:)
            @connection = connection
            @id = id
          end

          def call
            @connection.delete("/websets/v0/monitors/#{@id}")
            true
          end
        end
      end
    end
  end
end
