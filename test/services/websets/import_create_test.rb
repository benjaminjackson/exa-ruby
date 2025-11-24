# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class CreateImportTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
        end

        def test_initialize_with_connection_and_params
          service = CreateImport.new(
            @connection,
            size: 1000,
            count: 50,
            title: "Test Import",
            format: "csv",
            entity: { type: "company" }
          )

          assert_instance_of CreateImport, service
        end

        def test_call_creates_import_with_minimal_params
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: 1000,
                count: 50,
                title: "Test Company Import",
                format: "csv",
                entity: { type: "company" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_123",
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "company" },
                title: "Test Company Import",
                count: 50,
                metadata: {},
                failedReason: nil,
                failedAt: nil,
                failedMessage: nil,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/abc123",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1000,
            count: 50,
            title: "Test Company Import",
            format: "csv",
            entity: { type: "company" }
          )
          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal "import_123", result.id
          assert_equal "import", result.object
          assert_equal "pending", result.status
          assert_equal "csv", result.format
          assert_equal({ "type" => "company" }, result.entity)
          assert_equal "Test Company Import", result.title
          assert_equal 50, result.count
          assert_equal "https://upload.example.com/abc123", result.upload_url
          assert result.pending?
        end

        def test_call_creates_import_with_metadata
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: 2000,
                count: 100,
                title: "Import with metadata",
                format: "csv",
                entity: { type: "company" },
                metadata: { source: "customer_list", region: "us-west" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_456",
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "company" },
                title: "Import with metadata",
                count: 100,
                metadata: { source: "customer_list", region: "us-west" },
                failedReason: nil,
                failedAt: nil,
                failedMessage: nil,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/xyz789",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 2000,
            count: 100,
            title: "Import with metadata",
            format: "csv",
            entity: { type: "company" },
            metadata: { source: "customer_list", region: "us-west" }
          )
          result = service.call

          assert_equal "import_456", result.id
          assert_equal({ "source" => "customer_list", "region" => "us-west" }, result.metadata)
        end

        def test_call_creates_import_with_csv_options
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: 1500,
                count: 75,
                title: "CSV Import with identifier column",
                format: "csv",
                entity: { type: "company" },
                csv: { identifier: 1 }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_789",
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "company" },
                title: "CSV Import with identifier column",
                count: 75,
                metadata: {},
                failedReason: nil,
                failedAt: nil,
                failedMessage: nil,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/def456",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1500,
            count: 75,
            title: "CSV Import with identifier column",
            format: "csv",
            entity: { type: "company" },
            csv: { identifier: 1 }
          )
          result = service.call

          assert_equal "import_789", result.id
          assert_equal "CSV Import with identifier column", result.title
        end

        def test_call_creates_import_with_person_entity
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: 1200,
                count: 60,
                title: "People Import",
                format: "csv",
                entity: { type: "person" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_person_1",
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "person" },
                title: "People Import",
                count: 60,
                metadata: {},
                failedReason: nil,
                failedAt: nil,
                failedMessage: nil,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/person123",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1200,
            count: 60,
            title: "People Import",
            format: "csv",
            entity: { type: "person" }
          )
          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal "import_person_1", result.id
          assert_equal({ "type" => "person" }, result.entity)
          assert_equal "People Import", result.title
        end

        def test_call_creates_import_with_article_entity
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: 1300,
                count: 70,
                title: "Articles Import",
                format: "csv",
                entity: { type: "article" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_article_1",
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "article" },
                title: "Articles Import",
                count: 70,
                metadata: {},
                failedReason: nil,
                failedAt: nil,
                failedMessage: nil,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/article123",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1300,
            count: 70,
            title: "Articles Import",
            format: "csv",
            entity: { type: "article" }
          )
          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal "import_article_1", result.id
          assert_equal({ "type" => "article" }, result.entity)
          assert_equal "Articles Import", result.title
        end

        def test_call_creates_import_with_research_paper_entity
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: 1400,
                count: 80,
                title: "Research Papers Import",
                format: "csv",
                entity: { type: "research_paper" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_paper_1",
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "research_paper" },
                title: "Research Papers Import",
                count: 80,
                metadata: {},
                failedReason: nil,
                failedAt: nil,
                failedMessage: nil,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/paper123",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1400,
            count: 80,
            title: "Research Papers Import",
            format: "csv",
            entity: { type: "research_paper" }
          )
          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal "import_paper_1", result.id
          assert_equal({ "type" => "research_paper" }, result.entity)
          assert_equal "Research Papers Import", result.title
        end

        def test_call_creates_import_with_custom_entity
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: 1500,
                count: 90,
                title: "Custom Entities Import",
                format: "csv",
                entity: { type: "custom", description: "Healthcare providers in California" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_custom_1",
                object: "import",
                status: "pending",
                format: "csv",
                entity: { type: "custom", description: "Healthcare providers in California" },
                title: "Custom Entities Import",
                count: 90,
                metadata: {},
                failedReason: nil,
                failedAt: nil,
                failedMessage: nil,
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z",
                uploadUrl: "https://upload.example.com/custom123",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1500,
            count: 90,
            title: "Custom Entities Import",
            format: "csv",
            entity: { type: "custom", description: "Healthcare providers in California" }
          )
          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal "import_custom_1", result.id
          assert_equal({ "type" => "custom", "description" => "Healthcare providers in California" }, result.entity)
          assert_equal "Custom Entities Import", result.title
        end

        def test_call_raises_unauthorized_on_401
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .to_return(
              status: 401,
              body: { error: "Invalid API key" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1000,
            count: 50,
            title: "Test Import",
            format: "csv",
            entity: { type: "company" }
          )

          assert_raises(Exa::Unauthorized) do
            service.call
          end
        end

        def test_call_raises_bad_request_on_400
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .to_return(
              status: 400,
              body: { error: "Invalid parameters" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1000,
            count: 50,
            title: "Test Import",
            format: "csv",
            entity: { type: "company" }
          )

          assert_raises(Exa::BadRequest) do
            service.call
          end
        end

        def test_call_raises_internal_server_error_on_500
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .to_return(
              status: 500,
              body: { error: "Internal server error" }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          service = CreateImport.new(
            @connection,
            size: 1000,
            count: 50,
            title: "Test Import",
            format: "csv",
            entity: { type: "company" }
          )

          assert_raises(Exa::InternalServerError) do
            service.call
          end
        end
      end
    end
  end
end
