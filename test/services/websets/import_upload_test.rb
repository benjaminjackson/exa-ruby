# frozen_string_literal: true

require "test_helper"

module Exa
  module Services
    module Websets
      class UploadImportTest < Minitest::Test
        def setup
          @connection = Exa::Connection.build(api_key: "test_key")
          @test_file = "/tmp/test_upload.csv"
          File.write(@test_file, "name,url\nTest,https://test.com\n")
        end

        def teardown
          File.delete(@test_file) if File.exist?(@test_file)
        end

        def test_initialize_with_connection_file_path_and_params
          service = UploadImport.new(
            @connection,
            file_path: @test_file,
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" }
          )

          assert_instance_of UploadImport, service
        end

        def test_call_infers_file_size_from_file_path
          file_size = File.size(@test_file)

          # Stub the import creation request
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: file_size,
                count: 1,
                title: "Test Upload",
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
                uploadUrl: "https://s3.example.com/upload",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Stub the file upload request
          stub_request(:put, "https://s3.example.com/upload")
            .to_return(status: 200)

          service = UploadImport.new(
            @connection,
            file_path: @test_file,
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" }
          )

          result = service.call

          assert_instance_of Exa::Resources::Import, result
        end

        def test_call_uploads_file_to_upload_url
          file_size = File.size(@test_file)

          # Stub the import creation request
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: file_size,
                count: 1,
                title: "Test Upload",
                format: "csv",
                entity: { type: "company" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_456",
                object: "import",
                status: "pending",
                uploadUrl: "https://s3.example.com/upload456",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Stub the file upload request
          upload_stub = stub_request(:put, "https://s3.example.com/upload456")
            .with(
              body: File.read(@test_file),
              headers: { "Content-Type" => "text/csv" }
            )
            .to_return(status: 200)

          service = UploadImport.new(
            @connection,
            file_path: @test_file,
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" }
          )

          service.call

          assert_requested(upload_stub)
        end

        def test_call_returns_import_resource
          file_size = File.size(@test_file)

          # Stub the import creation request
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: file_size,
                count: 1,
                title: "Test Upload",
                format: "csv",
                entity: { type: "company" }
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
                title: "Test Upload",
                count: 1,
                uploadUrl: "https://s3.example.com/upload789",
                uploadValidUntil: "2023-11-07T06:31:56Z",
                createdAt: "2023-11-07T05:31:56Z",
                updatedAt: "2023-11-07T05:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Stub the file upload request
          stub_request(:put, "https://s3.example.com/upload789")
            .to_return(status: 200)

          service = UploadImport.new(
            @connection,
            file_path: @test_file,
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" }
          )

          result = service.call

          assert_instance_of Exa::Resources::Import, result
          assert_equal "import_789", result.id
          assert_equal "Test Upload", result.title
        end

        def test_call_raises_error_when_file_not_found
          service = UploadImport.new(
            @connection,
            file_path: "/nonexistent/file.csv",
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" }
          )

          error = assert_raises(Exa::Error) do
            service.call
          end

          assert_match(/file not found/i, error.message)
        end

        def test_call_raises_error_when_file_unreadable
          unreadable_file = "/tmp/unreadable_test.csv"
          File.write(unreadable_file, "test")
          File.chmod(0000, unreadable_file)

          service = UploadImport.new(
            @connection,
            file_path: unreadable_file,
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" }
          )

          error = assert_raises(Exa::Error) do
            service.call
          end

          assert_match(/permission denied|not readable/i, error.message)
        ensure
          File.chmod(0644, unreadable_file) if File.exist?(unreadable_file)
          File.delete(unreadable_file) if File.exist?(unreadable_file)
        end

        def test_call_with_metadata
          file_size = File.size(@test_file)

          # Stub the import creation request
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: file_size,
                count: 1,
                title: "Test Upload",
                format: "csv",
                entity: { type: "company" },
                metadata: { source: "test" }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_meta",
                object: "import",
                status: "pending",
                metadata: { source: "test" },
                uploadUrl: "https://s3.example.com/upload_meta",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Stub the file upload request
          stub_request(:put, "https://s3.example.com/upload_meta")
            .to_return(status: 200)

          service = UploadImport.new(
            @connection,
            file_path: @test_file,
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" },
            metadata: { source: "test" }
          )

          result = service.call

          assert_equal({ "source" => "test" }, result.metadata)
        end

        def test_call_with_csv_options
          file_size = File.size(@test_file)

          # Stub the import creation request
          stub_request(:post, "https://api.exa.ai/websets/v0/imports")
            .with(
              body: {
                size: file_size,
                count: 1,
                title: "Test Upload",
                format: "csv",
                entity: { type: "company" },
                csv: { identifier: 0 }
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                id: "import_csv",
                object: "import",
                status: "pending",
                uploadUrl: "https://s3.example.com/upload_csv",
                uploadValidUntil: "2023-11-07T06:31:56Z"
              }.to_json,
              headers: { "Content-Type" => "application/json" }
            )

          # Stub the file upload request
          stub_request(:put, "https://s3.example.com/upload_csv")
            .to_return(status: 200)

          service = UploadImport.new(
            @connection,
            file_path: @test_file,
            count: 1,
            title: "Test Upload",
            format: "csv",
            entity: { type: "company" },
            csv: { identifier: 0 }
          )

          result = service.call

          assert_instance_of Exa::Resources::Import, result
        end
      end
    end
  end
end
