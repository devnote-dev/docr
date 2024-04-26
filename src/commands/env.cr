module Docr::Commands
  class Env < Base
    def setup : Nil
      @name = "env"
      @summary = "docr environment management"
      @description = <<-DESC
        Manages the environment configuration for Docr. Specifying the 'name' argument
        will print that environment value to the terminal.
        DESC

      add_usage "env [options]"
      add_usage "env init [options]"

      add_command Init.new

      add_argument "name", description: "the name of the env variable", required: false
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      if value = arguments.get? "name"
        if value == "DOCR_CACHE"
          return stdout.puts CACHE_DIR
        elsif value == "DOCR_LIBRARY"
          return stdout.puts LIBRARY_DIR
        end
      end

      warn_cache = Dir.exists?(CACHE_DIR) ? "" : " (!)".colorize.yellow
      lib_cache = Dir.exists?(LIBRARY_DIR) ? "" : " (!)".colorize.yellow

      stdout << "DOCR_CACHE=" << CACHE_DIR << warn_cache << '\n'
      stdout << "DOCR_LIBRARY=" << LIBRARY_DIR << lib_cache << '\n'
    end

    class Init < Base
      def setup : Nil
        @name = "init"
        @summary = "initializes the environment"
        @description = "Creates the required files and directories for Docr to run."
      end

      def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
        Dir.mkdir_p CACHE_DIR unless Dir.exists? CACHE_DIR
        Dir.mkdir_p LIBRARY_DIR unless Dir.exists? LIBRARY_DIR
      end
    end
  end
end
