# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "fileutils"

class DotenvIntegrationTest < Minitest::Test
  def setup
    @original_api_key = ENV["EXA_API_KEY"]
    @original_dir = Dir.pwd
  end

  def teardown
    ENV["EXA_API_KEY"] = @original_api_key
    Dir.chdir(@original_dir)
  end

  def test_dotenv_loads_env_file_when_available
    # Create a temporary directory with a .env file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)

      # Write .env file with test API key
      File.write(".env", "EXA_API_KEY=test_key_from_dotenv_file\n")

      # Clear current ENV value
      ENV.delete("EXA_API_KEY")

      # Load dotenv (simulating what test_helper does)
      require "dotenv"
      Dotenv.load

      # Verify the key was loaded from .env
      assert_equal "test_key_from_dotenv_file", ENV["EXA_API_KEY"]
    end
  end

  def test_client_uses_env_variable_from_dotenv
    # Create a temporary directory with a .env file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)

      # Write .env file
      File.write(".env", "EXA_API_KEY=dotenv_client_test_key\n")

      # Clear current ENV value
      ENV.delete("EXA_API_KEY")

      # Load dotenv
      require "dotenv"
      Dotenv.load

      # Create client passing ENV variable (as shown in README)
      client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

      # Verify client picked up the key from environment
      assert_equal "dotenv_client_test_key", client.instance_variable_get(:@api_key)
    end
  end

  def test_explicit_api_key_overrides_dotenv
    # Create a temporary directory with a .env file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir)

      # Write .env file
      File.write(".env", "EXA_API_KEY=dotenv_key\n")

      # Load dotenv
      require "dotenv"
      Dotenv.load

      # Create client with explicit key (should override ENV)
      client = Exa::Client.new(api_key: "explicit_key")

      # Verify explicit key takes precedence
      assert_equal "explicit_key", client.instance_variable_get(:@api_key)
    end
  end

  def test_dotenv_not_required_when_env_already_set
    # Set ENV directly (simulating production environment)
    ENV["EXA_API_KEY"] = "production_key"

    # Create client with ENV (should work without dotenv)
    client = Exa::Client.new(api_key: ENV["EXA_API_KEY"])

    # Verify it uses the ENV key
    assert_equal "production_key", client.instance_variable_get(:@api_key)
  end
end
