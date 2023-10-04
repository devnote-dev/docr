module Docr::Commands
  class Version < Base
    def setup : Nil
      @name = "version"
      @summary = "shows version information"
      @description = "Shows the version information for Docr."
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout << "docr version " << Docr::VERSION
      stdout << " [" << Docr::BUILD_HASH << "] ("
      stdout << Docr::BUILD_DATE << ")\n"
    end
  end
end
