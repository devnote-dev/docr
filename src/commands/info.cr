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

      add_argument "query", required: true
      add_option 'l', "library", type: :single, default: "crystal"
      add_option 'p', "open-page"
      add_option 's', "open-source"
      add_option 'r', "result", type: :single, default: 1
      add_option 'v', "version", type: :single
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      if result = options.get("result").to_i32?
        if result < 1
          error "Result integer cannot be less than 1"
          exit_program
        end
      else
        error "Invalid integer for result option"
        exit_program
      end
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      name = options.get("library").as_s
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

      version ||= Library.get_versions_for(name).last
      library = Library.get name, version
      namespace, symbol, scope = Redoc.parse_query arguments.get("query").as_s

      if symbol
        types = library.resolve_all namespace, symbol, scope
        if types.empty? && namespace.empty? && name == "crystal"
          namespace << "Object"
          types = library.resolve_all namespace, symbol, scope
        end

        if types.empty?
          error "Could not resolve types or symbols for input"
          exit_program
        end

        result_index = options.get("result").to_i32
        max_types = types.size

        if result_index > max_types
          error "Result index out of range (#{result_index}/#{max_types})"
          exit_program
        end

        type = types[result_index - 1]

        unless max_types == 1
          stdout << max_types << " results found "
          stdout << "(select using '--result')\n\n".colorize.dark_gray
        end
      else
        unless type = library.resolve? namespace, symbol, scope
          if namespace.empty? && name == "crystal"
            namespace << "Object"
            type = library.resolve? namespace, symbol, scope
          end
        end

        unless type
          error "Could not resolve types or symbols for input"
          exit_program
        end
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
        return Formatters::Default.info stdout, type
      end

      uri = uri.to_s

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
