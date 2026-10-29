# typed: strict
# frozen_string_literal: true

# Direct RbConfig check because this loader runs during the very early
# init.rb bootstrap, before Library/Homebrew/os.rb is required and the
# OS module is defined. The check is byte-identical to OS.windows?.
require_relative "windows/gems" if RbConfig::CONFIG["host_os"].match?(/mswin|mingw|cygwin/)
