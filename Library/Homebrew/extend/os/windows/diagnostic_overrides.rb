# typed: true
# frozen_string_literal: true

module OS
  module Windows
    # Overrides for upstream Homebrew::Diagnostic::Checks methods that
    # make Linux/macOS assumptions that do not hold on Windows.
    #
    # Upstream Homebrew 7.x returns `Diagnostic::Finding` objects from checks.
    # Checks suppressed here return `nil` (no finding); the Windows-specific
    # replacements live in `extend/os/windows/diagnostic.rb`.
    module DiagnosticOverrides
      # check_for_installed_developer_tools tells the user to install
      # Clang or gcc. Both are macOS/Linux conventions and the message
      # is misleading on Windows where Visual Studio Build Tools or
      # MSRV/UCRT GCC are the conventional toolchains. The real runtime
      # readiness is surfaced by check_runtime_integrity.
      sig { returns(T.nilable(Homebrew::Diagnostic::Finding)) }
      def check_for_installed_developer_tools
        nil
      end

      # check_homebrew_prefix warns when the prefix is not /usr/local (or
      # /opt/homebrew on Apple Silicon). That distinction does not apply to
      # Windows, where the Brew Windows prefix is the supported location.
      sig { returns(T.nilable(Homebrew::Diagnostic::Finding)) }
      def check_homebrew_prefix
        nil
      end

      # check_user_path_1/2/3 advise editing ~/.profile to add bin to PATH.
      # That advice is meaningless on Windows (PATH is managed via
      # HKCU\Environment). check_path_brew_windows handles the equivalent
      # diagnostic with platform-appropriate guidance.
      sig { returns(T.nilable(Homebrew::Diagnostic::Finding)) }
      def check_user_path_1
        nil
      end

      sig { returns(T.nilable(Homebrew::Diagnostic::Finding)) }
      def check_user_path_2
        nil
      end

      sig { returns(T.nilable(Homebrew::Diagnostic::Finding)) }
      def check_user_path_3
        nil
      end
    end
  end
end

Homebrew::Diagnostic::Checks.prepend(OS::Windows::DiagnosticOverrides)
