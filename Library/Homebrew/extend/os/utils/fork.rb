# typed: strict
# frozen_string_literal: true

require_relative "../windows/utils/fork" if RbConfig::CONFIG["host_os"].match?(/mswin|mingw|cygwin/)
