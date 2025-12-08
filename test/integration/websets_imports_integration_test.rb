# frozen_string_literal: true

require "test_helper"

class WebsetsImportsIntegrationTest < Minitest::Test
  include WebsetsCleanupHelper

  def setup
    skip_unless_integration_enabled
    super
    @api_key = ENV.fetch("EXA_API_KEY", "test_key_for_vcr")
  end

  def teardown
    super
    Exa.reset
  end

  def test_create_import_with_minimal_parameters
    VCR.use_cassette("imports/create_import_minimal") do
      client = Exa::Client.new(api_key: @api_key)

      import = client.create_import(
        size: 1024,
        count: 10,
        title: "Test Company Import",
        format: "csv",
        entity: { type: "company" }
      )
      track_import(import.id)

      assert_instance_of Exa::Resources::Import, import
      assert import.id.start_with?("import_")
      assert_equal "import", import.object
      assert_equal "Test Company Import", import.title
      assert_equal "csv", import.format
      assert_equal({ "type" => "company" }, import.entity)
      assert_equal 10, import.count
      assert_includes ["pending", "processing", "completed"], import.status
      refute_nil import.created_at
      refute_nil import.updated_at
    end
  end

  def test_create_import_with_csv_identifier
    VCR.use_cassette("imports/create_import_with_csv_identifier") do
      client = Exa::Client.new(api_key: @api_key)

      import = client.create_import(
        size: 2048,
        count: 25,
        title: "Companies with CSV Identifier",
        format: "csv",
        entity: { type: "company" },
        csv: { identifier: 1 }
      )
      track_import(import.id)

      assert_instance_of Exa::Resources::Import, import
      assert_equal "import", import.object
      assert_equal "Companies with CSV Identifier", import.title
      assert_equal 25, import.count
      # Note: csv parameter is sent in request but not returned in response
    end
  end

  def test_create_import_with_metadata
    VCR.use_cassette("imports/create_import_with_metadata") do
      client = Exa::Client.new(api_key: @api_key)

      import = client.create_import(
        size: 512,
        count: 5,
        title: "Import with Custom Metadata",
        format: "csv",
        entity: { type: "company" },
        metadata: { source: "test", batch: "2025-11-23" }
      )
      track_import(import.id)

      assert_instance_of Exa::Resources::Import, import
      assert_equal "import", import.object
      assert_equal({ "source" => "test", "batch" => "2025-11-23" }, import.metadata)
    end
  end

  def test_get_import
    VCR.use_cassette("imports/get_import") do
      client = Exa::Client.new(api_key: @api_key)

      # Create an import first
      created_import = client.create_import(
        size: 1024,
        count: 15,
        title: "Import to Retrieve",
        format: "csv",
        entity: { type: "company" }
      )
      track_import(created_import.id)

      # Get the import by ID
      retrieved_import = client.get_import(created_import.id)

      assert_instance_of Exa::Resources::Import, retrieved_import
      assert_equal created_import.id, retrieved_import.id
      assert_equal created_import.title, retrieved_import.title
      assert_equal created_import.format, retrieved_import.format
      assert_equal created_import.count, retrieved_import.count
    end
  end

  def test_list_imports
    VCR.use_cassette("imports/list_imports") do
      client = Exa::Client.new(api_key: @api_key)

      # Create multiple imports
      import1 = client.create_import(
        size: 1024,
        count: 10,
        title: "First Import",
        format: "csv",
        entity: { type: "company" }
      )
      track_import(import1.id)

      import2 = client.create_import(
        size: 2048,
        count: 20,
        title: "Second Import",
        format: "csv",
        entity: { type: "company" }
      )
      track_import(import2.id)

      # List all imports
      imports_collection = client.list_imports

      assert_instance_of Exa::Resources::ImportCollection, imports_collection
      refute_nil imports_collection.data
      assert imports_collection.data.is_a?(Array)
      assert imports_collection.data.length >= 2

      # Verify our created imports are in the list
      # Note: data is an array of hashes, not Import objects
      import_ids = imports_collection.data.map { |item| item["id"] }
      assert_includes import_ids, import1.id
      assert_includes import_ids, import2.id
    end
  end

  def test_update_import_title
    VCR.use_cassette("imports/update_import_title") do
      client = Exa::Client.new(api_key: @api_key)

      # Create an import
      import = client.create_import(
        size: 1024,
        count: 10,
        title: "Original Title",
        format: "csv",
        entity: { type: "company" }
      )
      track_import(import.id)

      # Update the title
      updated_import = client.update_import(
        import.id,
        title: "Updated Title"
      )

      assert_instance_of Exa::Resources::Import, updated_import
      assert_equal import.id, updated_import.id
      assert_equal "Updated Title", updated_import.title
    end
  end

  def test_update_import_metadata
    VCR.use_cassette("imports/update_import_metadata") do
      client = Exa::Client.new(api_key: @api_key)

      # Create an import with initial metadata
      import = client.create_import(
        size: 1024,
        count: 10,
        title: "Import for Metadata Update",
        format: "csv",
        entity: { type: "company" },
        metadata: { version: "1.0" }
      )
      track_import(import.id)

      # Update the metadata (note: all metadata values must be strings)
      updated_import = client.update_import(
        import.id,
        metadata: { version: "2.0", updated: "yes" }
      )

      assert_instance_of Exa::Resources::Import, updated_import
      assert_equal import.id, updated_import.id
      assert_equal({ "version" => "2.0", "updated" => "yes" }, updated_import.metadata)
    end
  end

  def test_update_import_title_and_metadata
    VCR.use_cassette("imports/update_import_title_and_metadata") do
      client = Exa::Client.new(api_key: @api_key)

      # Create an import
      import = client.create_import(
        size: 1024,
        count: 10,
        title: "Before Update",
        format: "csv",
        entity: { type: "company" },
        metadata: { status: "draft" }
      )
      track_import(import.id)

      # Update both title and metadata (note: all metadata values must be strings)
      updated_import = client.update_import(
        import.id,
        title: "After Update",
        metadata: { status: "final", reviewed: "yes" }
      )

      assert_instance_of Exa::Resources::Import, updated_import
      assert_equal import.id, updated_import.id
      assert_equal "After Update", updated_import.title
      assert_equal({ "status" => "final", "reviewed" => "yes" }, updated_import.metadata)
    end
  end

  def test_delete_import
    VCR.use_cassette("imports/delete_import") do
      client = Exa::Client.new(api_key: @api_key)

      # Create an import
      import = client.create_import(
        size: 1024,
        count: 10,
        title: "Import to Delete",
        format: "csv",
        entity: { type: "company" }
      )
      import_id = import.id

      # Delete the import (no need to track since we're deleting it)
      deleted_import = client.delete_import(import_id)

      assert_instance_of Exa::Resources::Import, deleted_import
      assert_equal import_id, deleted_import.id
    end
  end

  def test_get_import_not_found
    VCR.use_cassette("imports/get_import_not_found") do
      client = Exa::Client.new(api_key: @api_key)

      assert_raises(Exa::NotFound) do
        client.get_import("import_nonexistent_12345")
      end
    end
  end

  def test_create_import_with_invalid_api_key
    VCR.use_cassette("imports/create_import_invalid_api_key") do
      client = Exa::Client.new(api_key: "invalid_api_key")

      # API returns 400 BadRequest for invalid API keys
      assert_raises(Exa::BadRequest) do
        client.create_import(
          size: 1024,
          count: 10,
          title: "Should Fail",
          format: "csv",
          entity: { type: "company" }
        )
      end
    end
  end

  def test_upload_url_present_after_creation
    VCR.use_cassette("imports/create_import_upload_url") do
      client = Exa::Client.new(api_key: @api_key)

      import = client.create_import(
        size: 1024,
        count: 10,
        title: "Import with Upload URL",
        format: "csv",
        entity: { type: "company" }
      )
      track_import(import.id)

      assert_instance_of Exa::Resources::Import, import
      # Upload URL may or may not be present depending on API behavior
      # Just verify the field exists (can be nil)
      assert_respond_to import, :upload_url
      assert_respond_to import, :upload_valid_until
    end
  end

  def test_import_status_helpers
    VCR.use_cassette("imports/create_import_status_helpers") do
      client = Exa::Client.new(api_key: @api_key)

      import = client.create_import(
        size: 1024,
        count: 10,
        title: "Test Status Helpers",
        format: "csv",
        entity: { type: "company" }
      )
      track_import(import.id)

      # Test status helper methods exist and work
      assert_respond_to import, :pending?
      assert_respond_to import, :processing?
      assert_respond_to import, :completed?
      assert_respond_to import, :failed?

      # Newly created import should be pending or processing
      assert(import.pending? || import.processing?,
             "Expected import to be pending or processing, got: #{import.status}")
    end
  end

  def test_upload_import_with_file
    VCR.use_cassette("imports/upload_import") do
      client = Exa::Client.new(api_key: @api_key)

      # Create a temporary test file
      test_file = "/tmp/integration_test_upload.csv"
      File.write(test_file, "company_name,website\nTest Company,https://example.com\n")

      begin
        import = client.upload_import(
          file_path: test_file,
          count: 1,
          title: "Integration Test Upload",
          format: "csv",
          entity: { type: "company" }
        )
        track_import(import.id)

        assert_instance_of Exa::Resources::Import, import
        assert import.id.start_with?("import_")
        assert_equal "import", import.object
        assert_equal "Integration Test Upload", import.title
        assert_equal "csv", import.format
        assert_equal({ "type" => "company" }, import.entity)
        assert_equal 1, import.count
        assert_includes ["pending", "processing", "completed"], import.status
        refute_nil import.created_at
        refute_nil import.updated_at
      ensure
        File.delete(test_file) if File.exist?(test_file)
      end
    end
  end
end
