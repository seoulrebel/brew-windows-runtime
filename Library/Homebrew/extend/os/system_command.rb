# typed: strict
# frozen_string_literal: true

require_relative "windows/system_command" if RbConfig::CONFIG["host_os"].match?(/mswin|mingw|cygwin/)
