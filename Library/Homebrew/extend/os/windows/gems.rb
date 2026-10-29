# typed: true
# frozen_string_literal: true

module OS
  module Windows
    module Gems
      # Windows executable lookup. Ruby's File.executable? on Windows
      # only returns true for files with .bat, .cmd, .exe or .com
      # extensions; it does not honor PATHEXT. RubyInstaller ships
      # console scripts like `bundle` as extension-less Ruby files
      # plus matching `.bat` wrappers, so only the `.bat` wrapper
      # passes File.executable?. The base find_in_path probes only
      # the bare name and so never finds the `.bat` variant. This
      # override probes the standard Windows executable extensions
      # in addition to the bare name.
      def find_in_path(executable)
        extensions = ["", ".bat", ".cmd", ".exe", ".com"]
        ENV.fetch("PATH").split(File::PATH_SEPARATOR).find do |path|
          extensions.any? do |ext|
            File.executable?(File.join(path, executable + ext))
          end
        end
      end
    end
  end
end

Utils::GemSetup.singleton_class.prepend(OS::Windows::Gems)
