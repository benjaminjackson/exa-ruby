# frozen_string_literal: true

require "test_helper"

# Checks that the commands use the option helpers on Exa::CLI::Base for
# JSON options instead of their own copies.
class OptionParsingTest < Minitest::Test
  COMMAND_FILES = (Dir[File.expand_path("../../exe/*", __dir__)] +
                   [File.expand_path("../../lib/exa/cli/search_parser.rb", __dir__)]).freeze

  def test_no_command_defines_its_own_json_parsing_helper
    offenders = COMMAND_FILES.select { |path| File.read(path).include?("def parse_json_or_file") }

    assert_empty offenders.map { |path| File.basename(path) }
  end
end
