# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class UpdateImportTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
          @import_id = "import_123"
        end

        def test_initialize_with_connection_and_id
          service = UpdateImport.new(@connection, id: @import_id, title: "Updated Title")

          assert_instance_of UpdateImport, service
        end

        def test_call_updates_import_title
          stub_request(:patch, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .with(
              body: {
                title: "Updated Import Title"
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: @import_id,
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "company" },
                title: "Updated Import Title",
                count: 50,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T06:00:00Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = UpdateImport.new(@connection, id: @import_id, title: "Updated Import Title")
          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal @import_id, result.id
          assert_equal "Updated Import Title", result.title
        end

        def test_call_updates_import_metadata
          stub_request(:patch, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .with(
              body: {
                metadata: { source: "new_source", updated: true }
              }.to_json
            )
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
                metadata: { source: "new_source", updated: true },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T06:00:00Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = UpdateImport.new(
            @connection,
            id: @import_id,
            metadata: { source: "new_source", updated: true }
          )
          result = service.call

          assert_equal({ "source" => "new_source", "updated" => true }, result.metadata)
        end

        def test_call_updates_both_title_and_metadata
          stub_request(:patch, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .with(
              body: {
                title: "New Title",
                metadata: { version: 2 }
              }.to_json
            )
            .to_return(
              status: 200,
              body: {
                id: @import_id,
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "company" },
                title: "New Title",
                count: 50,
                metadata: { version: 2 },
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T06:00:00Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = UpdateImport.new(
            @connection,
            id: @import_id,
            title: "New Title",
            metadata: { version: 2 }
          )
          result = service.call

          assert_equal "New Title", result.title
          assert_equal({ "version" => 2 }, result.metadata)
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:patch, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = UpdateImport.new(@connection, id: @import_id, title: "New Title")

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end

        def test_call_raises_not_found_on_404
          stub_request(:patch, "https://api.exa.ai/websets/v0/imports/nonexistent")
            .to_return(
              status: 404,
              body: { error: "Import not found" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = UpdateImport.new(@connection, id: "nonexistent", title: "New Title")

          assert_raises(Exa::NotFound) do
            service.call
          end
        end

        def test_call_raises_server_error_on_500
          stub_request(:patch, "https://api.exa.ai/websets/v0/imports/#{@import_id}")
            .to_return(
              status: 500,
              body: { error: "Internal server error" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = UpdateImport.new(@connection, id: @import_id, title: "New Title")

          assert_raises(Exa::InternalServerError) do
            service.call
          end
        end
      end
    end
  end
end
