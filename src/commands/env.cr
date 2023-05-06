module Docr::Commands
  class Env < Base
    def setup : Nil
      @name = "env"
      @summary = "docr environment management"
      @description = <<-DESC
        Manages the environment configuration for Docr. Specifying the 'name' argument
        will print that environment value to the terminal.
        DESC

      add_argument "name", description: "the name of the env variable", required: false
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      if value = arguments.get? "name"
        # FIXME: this is broken for some reason
        # case value
        # when "DOCR_CACHE"   then stdout.puts Library::CACHE_DIR
        # when "DOCR_LIBRARY" then stdout.puts Library::LIBRARY_DIR
        # end

        if value == "DOCR_CACHE"
          stdout.puts Library::CACHE_DIR
        elsif value == "DOCR_LIBRARY"
          stdout.puts Library::LIBRARY_DIR
        end

        return
      end

      stdout << "DOCR_CACHE=" << Library::CACHE_DIR << '\n'
      stdout << "DOCR_LIBRARY=" << Library::LIBRARY_DIR << '\n'
    end
  end
end
