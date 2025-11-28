# frozen_string_literal: true

require "test_helper"

class ImportTest < Minitest::Test
  def test_initializes_with_all_fields
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "pending",
      format: "csv",
      entity: { "type" => "company" },
      title: "Q4 2024 Company Import",
      count: 500,
      metadata: { "source" => "crunchbase" },
      failed_reason: nil,
      failed_at: nil,
      failed_message: nil,
      created_at: "2024-01-15T10:00:00Z",
      updated_at: "2024-01-15T10:00:00Z",
      upload_url: "https://upload.example.com/abc123",
      upload_valid_until: "2024-01-15T11:00:00Z"
    )

    assert_equal "imp_123", import.id
    assert_equal "import", import.object
    assert_equal "pending", import.status
    assert_equal "csv", import.format
    assert_equal({ "type" => "company" }, import.entity)
    assert_equal "Q4 2024 Company Import", import.title
    assert_equal 500, import.count
    assert_equal({ "source" => "crunchbase" }, import.metadata)
    assert_nil import.failed_reason
    assert_nil import.failed_at
    assert_nil import.failed_message
    assert_equal "2024-01-15T10:00:00Z", import.created_at
    assert_equal "2024-01-15T10:00:00Z", import.updated_at
    assert_equal "https://upload.example.com/abc123", import.upload_url
    assert_equal "2024-01-15T11:00:00Z", import.upload_valid_until
  end

  def test_initializes_with_failed_fields
    import = Exa::Resources::Import.new(
      id: "imp_456",
      object: "import",
      status: "failed",
      failed_reason: "invalid_format",
      failed_at: "2024-01-15T10:30:00Z",
      failed_message: "CSV format is invalid"
    )

    assert_equal "imp_456", import.id
    assert_equal "failed", import.status
    assert_equal "invalid_format", import.failed_reason
    assert_equal "2024-01-15T10:30:00Z", import.failed_at
    assert_equal "CSV format is invalid", import.failed_message
  end

  def test_to_h_returns_all_fields_as_hash
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "completed",
      format: "csv",
      entity: { "type" => "company" },
      title: "Test Import",
      count: 100,
      metadata: { "key" => "value" },
      created_at: "2024-01-15T10:00:00Z",
      updated_at: "2024-01-15T10:00:00Z",
      upload_url: "https://upload.example.com/test",
      upload_valid_until: "2024-01-15T11:00:00Z"
    )

    hash = import.to_h

    assert_equal "imp_123", hash[:id]
    assert_equal "import", hash[:object]
    assert_equal "completed", hash[:status]
    assert_equal "csv", hash[:format]
    assert_equal({ "type" => "company" }, hash[:entity])
    assert_equal "Test Import", hash[:title]
    assert_equal 100, hash[:count]
    assert_equal({ "key" => "value" }, hash[:metadata])
    assert_equal "2024-01-15T10:00:00Z", hash[:created_at]
    assert_equal "2024-01-15T10:00:00Z", hash[:updated_at]
    assert_equal "https://upload.example.com/test", hash[:upload_url]
    assert_equal "2024-01-15T11:00:00Z", hash[:upload_valid_until]
  end

  def test_to_h_compacts_nil_values
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "pending"
    )

    hash = import.to_h

    assert_equal "imp_123", hash[:id]
    assert_equal "import", hash[:object]
    assert_equal "pending", hash[:status]
    refute hash.key?(:failed_reason)
    refute hash.key?(:failed_at)
    refute hash.key?(:failed_message)
  end

  def test_is_frozen_after_initialization
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "pending"
    )

    assert import.frozen?
  end

  def test_pending_status_helper
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "pending"
    )

    assert import.pending?
    refute import.processing?
    refute import.completed?
    refute import.failed?
  end

  def test_processing_status_helper
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "processing"
    )

    refute import.pending?
    assert import.processing?
    refute import.completed?
    refute import.failed?
  end

  def test_completed_status_helper
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "completed"
    )

    refute import.pending?
    refute import.processing?
    assert import.completed?
    refute import.failed?
  end

  def test_failed_status_helper
    import = Exa::Resources::Import.new(
      id: "imp_123",
      object: "import",
      status: "failed"
    )

    refute import.pending?
    refute import.processing?
    refute import.completed?
    assert import.failed?
  end
end
