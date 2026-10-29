# typed: true
# frozen_string_literal: true

module OS
  module Windows
    # Overrides for upstream Homebrew::Diagnostic::Checks methods that
    # make Linux/macOS assumptions that do not hold on Windows.
    module DiagnosticOverrides
      # check_git_newline_settings uses backticks to call `git config`.
      # On Windows, Ruby backticks split bare "git" and exec it directly
      # without a shell, which fails when git is only reachable via
      # PATH set by the launcher. Route through the vendored git.
      sig { returns(T.nilable(String)) }
      def check_git_newline_settings
        return unless Utils::Git.available?

        git_path = ENV["HOMEBREW_GIT_PATH"].to_s
        return nil if git_path.empty? || !File.file?(git_path)

        autocrlf = HOMEBREW_REPOSITORY.cd do
          Utils.popen_read(git_path, "config", "--get", "core.autocrlf").chomp
        end
        return if autocrlf != "true"

        <<~EOS
          Suspicious Git newline settings found.

          The detected Git newline settings will cause checkout problems:
            core.autocrlf = #{autocrlf}

          If you are not routinely dealing with Windows-based projects,
          consider removing these by running:
            git config --global core.autocrlf input
        EOS
      end

      # check_for_installed_developer_tools tells the user to install
      # Clang or gcc. Both are macOS/Linux conventions and the message
      # is misleading on Windows where Visual Studio Build Tools or
      # MSYS2/UCRT GCC are the conventional toolchains. Make this
      # check a no-op on Windows; the real toolchain readiness is
      # surfaced by check_runtime_integrity from windows-diagnostics.
      sig { returns(T.nilable(String)) }
      def check_for_installed_developer_tools
        nil
      end

      # check_homebrew_prefix warns when prefix != /usr/local (or
      # /opt/homebrew on Apple Silicon). That distinction does not
      # apply to Windows where Brew Windows installs to
      # %LOCALAPPDATA%\Homebrew and bottles are not available anyway.
      # Suppress the Tier 3 warning - Windows IS the supported prefix
      # for this distribution.
      sig { returns(T.nilable(String)) }
      def check_homebrew_prefix
        nil
      end

      # check_user_path_1/2/3 advise editing ~/.profile to add bin to
      # PATH. The advice is meaningless on Windows (no ~/.profile in
      # PowerShell/cmd workflows; PATH is managed via
      # HKCU\Environment). The Windows-aware check_path_brew_windows
      # (added by windows-diagnostics) handles the equivalent
      # diagnostic with platform-appropriate guidance.
      sig { returns(T.nilable(String)) }
      def check_user_path_1
        nil
      end

      sig { returns(T.nilable(String)) }
      def check_user_path_2
        nil
      end

      sig { returns(T.nilable(String)) }
      def check_user_path_3
        nil
      end

      # check_git_status uses backticks against bare "git" inside each
      # repo's directory. As with check_git_newline_settings, the
      # Ruby/Windows split-and-exec path skips PATH lookup. Use the
      # vendored git executable explicitly.
      sig { returns(T.nilable(String)) }
      def check_git_status
        return unless Utils::Git.available?

        git_path = ENV["HOMEBREW_GIT_PATH"].to_s
        return nil if git_path.empty? || !File.file?(git_path)

        message = nil
        repos = {
          "Homebrew/brew"          => HOMEBREW_REPOSITORY,
          "Homebrew/homebrew-core" => CoreTap.instance.path,
          "Homebrew/homebrew-cask" => CoreCaskTap.instance.path,
        }

        repos.each do |name, path|
          next unless path.exist?

          status = path.cd do
            Utils.popen_read(git_path, "status", "--untracked-files=all", "--porcelain")
          end
          next if status.blank?

          message ||= ""
          message += "
" unless message.empty?
          message += <<~EOS
            You have uncommitted modifications to #{name}.
            If this is a surprise to you, then you should stash these modifications.
            Stashing returns Homebrew to a pristine state but can be undone
            should you later need to do so for some reason.
              git -C "#{path}" stash -u && git -C "#{path}" clean -d -f
          EOS

          modified = status.split("
")
          message += inject_file_list modified, <<~EOS

            Uncommitted files:
          EOS
        end

        message
      end
    end
  end
end

Homebrew::Diagnostic::Checks.prepend(OS::Windows::DiagnosticOverrides)
