module Docr::Commands
  class Info < Base
    def setup : Nil
      @name = "info"
      @summary = "gets information about a symbol"
      @description = <<-DESC
        Gets information about a specified type/namespace or symbol. This uses
        Crystal path syntax, meaning the following commands are valid:

        • docr info puts
        • docr info ::JSON.parse
        • docr info JSON::Any#as_s

        However, the following commands are not valid:

        • docr info ::puts
        • docr info JSON::parse
        • docr info JSON#Any.as_s

        Type namespaces are separated by '::', class methods are denoted by '.'
        and instance methods are denoted by '#'. The type lookup order starts
        at the top-level hence why '::puts' is invalid, '::JSON' is valid for
        semantic reasons.
        DESC

      add_argument "library"
      add_argument "input"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      super

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
      query = Redoc.parse_query arguments.get("input").as_s

      if type = project.resolve? *query
        return Formatters::Default.format_info stdout, type, true
      end

      if query[0].empty? && name == "crystal"
        query[0] << "Object"
        if type = project.resolve? *query
          return Formatters::Default.format_info stdout, type, true
        end
      end

      error "could not resolve types or symbols for input"
    end
  end
end
