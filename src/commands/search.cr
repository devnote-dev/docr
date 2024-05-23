module Docr::Commands
  class Search < Base
    def setup : Nil
      @name = "search"
      @summary = "search for a symbol or type"

      add_argument "library"
      add_argument "symbol"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      unless arguments.has? "input"
        arg = Cling::Argument.new "input"
        arg.value = arguments.get "library"

        arguments.hash["input"] = arg
        arguments.hash["library"].value = Cling::Value.new "crystal"
      end
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = arguments.get("library").as_s

      unless Library.exists? name
        error "library '#{name}' not imported"
        exit_program
      end

      version = Library.get_versions_for(name).sort.last
      project = Library.get name, version
    end
  end
end
