# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      module Imports
        class DeleteTest < Minitest::Test
          def setup
            @connection = Exa::Connection.build(api_key: "test_key")
            @import_id = "import_123"
          end

          def test_initialize_with_connection_and_id
            service = Delete.new(@connection, id: @import_id)

            assert_instance_of Delete, service
          end

          def test_call_deletes_import_and_returns_deleted_resource
            stub_request(:delete, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
              .to_return(
                status: 200,
                body: {
                  id: @import_id,
                  object: "import",
                  status: "pending",
                  format: "csv",
                  entity: { type: "company" },
                  title: "Deleted Import",
                  count: 50,
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T06:00:00Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: @import_id)
            result = service.call

            assert_instance_of Exa::Resources::Import, result
            assert_equal @import_id, result.id
            assert_equal "import", result.object
            assert_equal "Deleted Import", result.title
          end

          def test_call_sends_delete_request_to_correct_endpoint
            stub_request(:delete, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
              .to_return(
                status: 200,
                body: {
                  id: @import_id,
                  object: "import",
                  status: "pending",
                  format: "csv",
                  entity: { type: "company" },
                  title: "Test Import",
                  count: 50,
                  createdAt: "2023-11-07T05:31:56Z",
                  updatedAt: "2023-11-07T06:00:00Z"
                }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: @import_id)
            service.call

            assert_requested :delete, "https://api.exa.ai/websets/v0/imports/#{@import_id}"
          end

          def test_call_raises_unauthorized_on_401
            stub_request(:delete, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
              .to_return(
                status: 401,
                body: { error: "Invalid API key" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: @import_id)

            assert_raises(Exa::Unauthorized) do
              service.call
            end
          end

          def test_call_raises_not_found_on_404
            stub_request(:delete, "https://api.exa.ai/websets/v0/imports/nonexistent")
              .to_return(
                status: 404,
                body: { error: "Import not found" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: "nonexistent")

            assert_raises(Exa::NotFound) do
              service.call
            end
          end

          def test_call_raises_server_error_on_500
            stub_request(:delete, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
              .to_return(
                status: 500,
                body: { error: "Internal server error" }.to_json,
                headers: { "Content-Type" => "application/json" }
              )

            service = Delete.new(@connection, id: @import_id)

            assert_raises(Exa::InternalServerError) do
              service.call
            end
          end
        end
      end
    end
  end
end
