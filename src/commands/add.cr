module Docr::Commands
  class Add < Base
    def setup : Nil
      @name = "add"
      @summary = "imports documentation for a library"
      @description = <<-DESC
        Imports documentation for the Crystal standard library or a third-party library
        (or shard). If you are importing the standard library, the 'source' argument
        should be the version to import ("latest" also works here). Otherwise, the
        'source' argument should be a URI that resolves to the library's repository
        (which is handled by git).
        DESC

      add_usage "docr add <name> <source> [options]"
      add_usage "docr add <name> latest [options]"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
    end
  end
end
