# typed: true
# frozen_string_literal: true

module OS
  module Windows
    module SystemCommandWrapper
      # Replace the fork+exec implementation with Process.spawn, which is
      # the supported way to launch a child process on Windows (Ruby's
      # fork is unimplemented there). Drops the Process::UID privilege
      # handoff since Windows has no setuid model.
      # Options that the upstream fork+exec path accepts but Windows
      # Process.spawn rejects (`wrong exec option symbol`). Strip them
      # silently - they are POSIX-only semantics (process groups, uid
      # handoff) that have no Windows equivalent.
      UNSUPPORTED_SPAWN_OPTIONS = [:pgroup, :unsetenv_others, :close_others].freeze

      # Upstream wraps every non-sudo invocation with `/usr/bin/env VAR=val`
      # which works on macOS/Linux but doesn't exist as a native Windows
      # path. Process.spawn accepts the env hash directly so the wrapper
      # adds no value here.
      def command_prefix
        sudo? ? super : []
      end

      def exec3(env, executable, *args, **options)
        in_r, in_w = IO.pipe
        options[:in] = in_r
        in_w.sync = true

        out_r, out_w = IO.pipe
        options[:out] = out_w

        err_r, err_w = IO.pipe
        options[:err] = err_w

        UNSUPPORTED_SPAWN_OPTIONS.each { |key| options.delete(key) }

        # Resolve bare "git"/"curl"/"ruby" to the vendored executables.
        # Process.spawn on Windows does not search PATH the way the POSIX
        # fork+exec path does, and several call sites (e.g. Tap#git_command!
        # -> SystemCommand.run!("git", ...)) pass a bare command name.
        case executable.to_s
        when "git"
          candidate = ENV["HOMEBREW_GIT_PATH"].to_s
          executable = candidate if !candidate.empty? && File.file?(candidate)
        when "curl"
          candidate = ENV["HOMEBREW_CURL_PATH"].to_s
          executable = candidate if !candidate.empty? && File.file?(candidate)
        when "ruby"
          candidate = ENV["HOMEBREW_RUBY_PATH"].to_s
          executable = candidate if !candidate.empty? && File.file?(candidate)
        end

        # Bash shebang shims (e.g. Library/Homebrew/shims/shared/git)
        # can't be exec'd directly by Windows CreateProcess. Detect the
        # `#!/.../bash` header and route through the vendored bash.exe.
        if executable.to_s.is_a?(String) && File.file?(executable.to_s)
          first_line = File.open(executable.to_s, "rb") { |f| f.read(256) }.to_s
          if first_line.start_with?("#!") && first_line.include?("bash")
            # Locate the vendored bash relative to git.exe (mingit ships both).
            git_path = ENV["HOMEBREW_GIT_PATH"].to_s
            bash = ENV["HOMEBREW_BASH"]
            if (bash.nil? || bash.empty?) && !git_path.empty?
              # git_path is .../runtime/mingit/cmd/git.exe; bash lives at
              # .../runtime/mingit/usr/bin/bash.exe (sibling of `cmd`).
              mingit_root = File.dirname(File.dirname(git_path))
              bash = File.join(mingit_root, "usr", "bin", "bash.exe")
            end
            if bash && File.file?(bash)
              args = [executable.to_s, *args]
              executable = bash
            end
          end
        end

        # `Tty.width` shells out to `/bin/stty` which doesn't exist on
        # Windows. Use a constant value instead - this only sets COLUMNS
        # for the child process and doesn't affect anything Windows tools
        # care about.
        pid = Process.spawn(
          env.merge({ "COLUMNS" => "80" }),
          executable,
          *args,
          **options,
        )
        wait_thr = Process.detach(pid)

        [in_w, out_r, err_r, wait_thr]
      rescue
        in_w&.close
        out_r&.close
        err_r&.close
        raise
      ensure
        in_r&.close
        out_w&.close
      end
    end
  end
end

SystemCommand.prepend(OS::Windows::SystemCommandWrapper)
