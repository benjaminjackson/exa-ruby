# frozen_string_literal: true

require "test_helper"

class ExaTest < Minitest::Test
  def teardown
    # Reset configuration after each test to avoid pollution
    Exa.reset
  end

  def test_configure_yields_module_for_configuration
    result = nil
    Exa.configure do |config|
      result = config
    end

    assert_equal Exa, result
  end

  def test_api_key_can_be_set_through_configure_block
    Exa.configure do |config|
      config.api_key = "test_api_key_123"
    end

    assert_equal "test_api_key_123", Exa.api_key
  end

  def test_api_key_can_be_set_directly
    Exa.api_key = "direct_key_456"

    assert_equal "direct_key_456", Exa.api_key
  end

  def test_api_key_defaults_to_nil
    # After reset in teardown, api_key should be nil
    assert_nil Exa.api_key
  end

  def test_base_url_has_default_value
    # After reset, base_url should return to its default value
    assert_equal "https://api.exa.ai", Exa.base_url
  end

  def test_base_url_can_be_set_through_configure_block
    Exa.configure do |config|
      config.base_url = "https://custom.api.com"
    end

    assert_equal "https://custom.api.com", Exa.base_url
  end

  def test_base_url_can_be_set_directly
    Exa.base_url = "https://another.api.com"

    assert_equal "https://another.api.com", Exa.base_url
  end

  def test_timeout_has_default_value
    # After reset, timeout should return to its default value of 30
    assert_equal 30, Exa.timeout
  end

  def test_timeout_can_be_set_through_configure_block
    Exa.configure do |config|
      config.timeout = 60
    end

    assert_equal 60, Exa.timeout
  end

  def test_timeout_can_be_set_directly
    Exa.timeout = 120

    assert_equal 120, Exa.timeout
  end

  def test_reset_clears_api_key_to_nil
    Exa.api_key = "some_key"
    Exa.reset

    assert_nil Exa.api_key
  end

  def test_reset_restores_base_url_to_default
    Exa.base_url = "https://custom.api.com"
    Exa.reset

    assert_equal "https://api.exa.ai", Exa.base_url
  end

  def test_reset_restores_timeout_to_default
    Exa.timeout = 999
    Exa.reset

    assert_equal 30, Exa.timeout
  end

  def test_reset_clears_all_configuration_at_once
    Exa.configure do |config|
      config.api_key = "test_key"
      config.base_url = "https://custom.api.com"
      config.timeout = 60
    end

    Exa.reset

    assert_nil Exa.api_key
    assert_equal "https://api.exa.ai", Exa.base_url
    assert_equal 30, Exa.timeout
  end
end
