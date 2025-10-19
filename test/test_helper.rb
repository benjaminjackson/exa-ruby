# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "exa"
require "minitest/autorun"
require "webmock/minitest"

# Disable external network connections in tests
WebMock.disable_net_connect!(allow_localhost: true)
