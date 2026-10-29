# typed: true
# frozen_string_literal: true

module OS
  module Windows
    module DevelopmentTools
      # Brew Windows v2 prefers prebuilt Windows binary distributions over
      # source builds (formulae point at .zip artifacts with no compile
      # step). The UnbottledError check at formula_installer.rb:558 fires
      # when no compiler is found and we're not pouring a bottle, but it
      # is the wrong gate on Windows: most Windows-shaped formulae don't
      # need a compiler at all. Returning true here unblocks installs of
      # binary-only formulae. Formulae that DO need a Windows compiler
      # should declare `depends_on "..."` for the relevant tool, which
      # the dependency_collector will still enforce.
      sig { returns(T::Boolean) }
      def installed?
        true
      end
    end
  end
end

DevelopmentTools.singleton_class.prepend(OS::Windows::DevelopmentTools)
