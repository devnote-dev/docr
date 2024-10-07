module Docr::Commands
  class Info < Base
    def setup : Nil
      @name = "info"
      @summary = "gets information about a symbol"
      @description = <<-DESC
        Gets information about a specified type/namespace or symbol. This uses
        Crystal path syntax, meaning the following commands are valid:

        • docr info raise
        • docr info ::puts
        • docr info JSON.parse
        • docr info ::JSON::Any#as_s

        However, the following commands are not valid:

        • docr info to_s.nil?
        • docr info IO.Memory
        • docr info JSON::parse
        • docr info JSON#Any.as_s

        Type namespaces are separated by '::', class methods are denoted by '.'
        and instance methods are denoted by '#'. The type lookup order starts
        at the top-level and recurses down the type path.
        DESC

      add_argument "library"
      add_argument "input"
      add_option 'p', "open-page"
      add_option 's', "open-source"
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

      if options.has? "open-page"
        if name == "crystal"
          uri = URI.parse "https://crystal-lang.org/api/#{version}/"
        else
          uri = URI.parse Library.get_source(name) + "/#{version}/"
        end

        build_page_uri(uri, type)
      elsif options.has? "open-source"
        uri = build_source_uri type
      else
        return Formatters::Default.format_info stdout, type, true
      end

      {% if flag?(:win32) %}
        Process.run "cmd /c start #{uri}", shell: true
      {% elsif flag?(:macos) %}
        Process.run "open", [uri], shell: true
      {% else %}
        {"xdg-open", "sensible-browser", "firefox", "google-chrome"}.each do |command|
          return if Process.run(command, [uri], shell: true).success?
        end

        error "Could not find a program to open URI:"
        error uri
        exit_program
      {% end %}
    end

    private def build_page_uri(uri : URI, type : Redoc::Type) : Nil
      case type
      in Redoc::Namespace, Redoc::Enum, Redoc::Alias, Redoc::Annotation
        uri.path += type.path
      in Redoc::Def, Redoc::Macro
        if ref_path = type.parent.try &.path
          uri.path += ref_path
        else
          uri.path += "toplevel.html"
        end
        uri.fragment = type.html_id
      in Redoc::Const
        if ref_path = type.parent.try &.path
          uri.path += ref_path
          uri.fragment = type.name
        elsif type.top_level?
          uri.path += "toplevel.html"
          uri.fragment = type.name
        else
          error "Could not resolve a location for constant type"
          exit_program
        end
      in Redoc::Type
        raise "unreachable"
      end
    end

    private def build_source_uri(type : Redoc::Type) : URI
      if type.responds_to?(:locations)
        url = type.locations[0].url
      elsif type.responds_to?(:location)
        url = type.location.try &.url
      end

      unless url
        error "Could not resolve a location for type"
        exit_program
      end

      URI.parse url
    end
  end
end
