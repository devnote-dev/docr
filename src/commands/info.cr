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
      # TODO: maybe separate to --open-page and --open-source
      add_option 'o', "open"
      add_option 'v', "version", type: :single
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
      version = options.get?("version").try &.as_s

      unless Library.exists?(name, version)
        if version
          if Library.exists?(name)
            error "Version '#{version}' of #{name} not found or imported"
            exit_program
          end
        end

        error "Library '#{name}' not imported"
        exit_program
      end

      version ||= Library.get_versions_for(name).sort.last
      project = Library.get name, version
      query = Redoc.parse_query arguments.get("input").as_s

      unless type = project.resolve? *query
        if query[0].empty? && name == "crystal"
          query[0] << "Object"
          type = project.resolve? *query
        end
      end

      unless type
        error "Could not resolve types or symbols for input"
        exit_program
      end

      unless options.has? "open"
        return Formatters::Default.format_info stdout, type, true
      end

      if type.responds_to?(:locations)
        path = type.locations[0].url
      elsif type.responds_to?(:location)
        path = type.location.try &.url
      end

      unless path
        error "Could not resolve a location for type"
        exit_program
      end

      {% if flag?(:win32) %}
        Process.run "cmd /c start #{path}", shell: true
      {% elsif flag?(:macos) %}
        Process.run "open", [path], shell: true
      {% else %}
        {"xdg-open", "sensible-browser", "firefox", "google-chrome"}.each do |command|
          return if Process.run(command, [path], shell: true).success?
        end

        error "Could not find a program to open location:"
        error path
        exit_program
      {% end %}
    end
  end
end
