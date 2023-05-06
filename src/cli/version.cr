module Docr::Commands
  class Version < BaseCommand
    def setup : Nil
      @name = "version"
      @summary = "shows version information"
      @description = "Shows the version information for Docr."
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts "Docr version #{Docr::VERSION} #{Docr::BUILD_HASH} (#{Docr::BUILD_DATE})"
    end
  end
end
