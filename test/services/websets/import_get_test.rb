# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class GetImportTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
          @import_id = "import_123"
        end

        def test_initialize_with_connection_and_id
          service = GetImport.new(@connection, id: @import_id)

          assert_instance_of GetImport, service
        end

        def test_call_gets_import_by_id
          stub_request(:get, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .to_return(
              status: 200,
              body: {
                id: @import_id,
                object: "import",
                status: "completed",
                format: "csv",
                entity: { type: "company" },
                title: "Test Import",
                count: 100,
                metadata: { source: "test" },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/abc123",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetImport.new(@connection, id: @import_id)
          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal @import_id, result.id
          assert_equal "import", result.object
          assert_equal "completed", result.status
          assert_equal "csv", result.format
          assert_equal({ "type" => "company" }, result.entity)
          assert_equal "Test Import", result.title
          assert_equal 100, result.count
          assert result.completed?
        end

        def test_call_gets_failed_import
          stub_request(:get, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .to_return(
              status: 200,
              body: {
                id: @import_id,
                object: "import",
                status: "failed",
                format: "csv",
                entity: { type: "company" },
                title: "Failed Import",
                count: 0,
                failedReason: "invalid_format",
                failedAt: "2023-11-07T05:31:56Z",
                failedMessage: "Invalid CSV format",
                createdAt: "2023-11-07T05:00:00Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetImport.new(@connection, id: @import_id)
          result = service.call

          assert_equal "failed", result.status
          assert_equal "invalid_format", result.failed_reason
          assert_equal "Invalid CSV format", result.failed_message
          refute_nil result.failed_at
          assert result.failed?
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:get, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetImport.new(@connection, id: @import_id)

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end

        def test_call_raises_not_found_on_404
          stub_request(:get, "https://api.exa.ai/websets/v0/imports/nonexistent")
            .to_return(
              status: 404,
              body: { error: "Import not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetImport.new(@connection, id: "nonexistent")

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_server_error_on_500
          stub_request(:get, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .to_return(
              status: 500,
              body: { error: "Internal server error" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = GetImport.new(@connection, id: @import_id)

          assert_raises(Exa::InternalServerError) do
            service.call
          end
        end
      end
    end
  end
end
