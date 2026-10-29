# typed: strict
# frozen_string_literal: true

require_relative "windows/diagnostic_overrides" if RbConfig::CONFIG["host_os"].match?(/mswin|mingw|cygwin/)
