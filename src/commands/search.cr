{% skip_file %}

module Docr::Commands
  class Search < Base
    QUERY_RULE = /^(?<ns>(?:::)?[A-Z_]{1,}(?:\w+|::)+)?(?<scp>\.|#|\s+)?(?<sym>[a-zA-Z_]{1,}[\w!?=]|[!?<^>=+\-~\/*&%\[|\]])?$/

    def setup : Nil
      @name = "search"
      @summary = "searches for a symbol or type"
      @description = <<-DESC
        Searches for types/namespaces and symbols in a given library. If no library is
        specified, the latest version of the Crystal standard library documentation is
        used instead.
        DESC

      add_usage "docr search [library] <type|symbol> [options]"
      add_usage "docr search [library] <type> <symbol> [options]"

      add_argument "library", description: "the name of the library"
      add_argument "symbol", multiple: true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      lib_name = arguments.get("library").as_s
      symbol = arguments.get?("symbol").try(&.as_a) || %w[]

      debug "library: #{lib_name.inspect}"
      debug "symbol: #{symbol.inspect}"

      matches = QUERY_RULE.match symbol.join ' '
      unless matches
        return error "Could not resolve any types or namespaces for that symbol"
      end

      versions = Library.get_versions_for lib_name

      if versions.empty?
        format = "docr add #{lib_name} <source>".colorize.blue
        error "No documentation is available for this library"
        error "To import a version of this library, run '#{format}'"
        return
      end

      library = Library.fetch lib_name
      data = library.data.program
      namespace = matches["ns"]? || "crystal"

      res = resolve_type data, [namespace]
      if res.nil? && lib_name != "crystal"
        p! data.types[0].name
        res = resolve_type data.types[0], [namespace]
      end
      p! res.try &.name
      if res.nil?
        return error "Could not resolve any types or namespaces from that symbol"
      end
      p! namespace

      scope = Docr::Search::Scope.from matches["scp"]?
      symbol = matches["sym"]?

      search = Docr::Search.new
      search.apply_filters res, namespace, scope, symbol
      unless search.results?
        return error "Could not resolve any types or namespaces from that symbol"
      end

      pp! search
      return

      str = String.build do |io|
        io << "Search Results:\n\n"

        results.each do |kind, result|
          case kind
          when .constant?
            result.each do |const|
              def_source_for const
              io << const.value.map(&.colorize.blue).join("::")
              io << '\n'
            end
          when .def?, .macro?
            result.each do |method|
              def_source_for method
              if kind.def?
                io << "def ".colorize.red
              else
                io << "macro ".colorize.red
              end

              if method.value.size <= 2
                if method.value[1].includes?('(')
                  io << method.value[0].colorize.magenta
                  io << method.value[1]
                else
                  io << method.value[0].colorize.blue
                  io << (method.instance? ? '#' : '.')
                  io << method.value[1].colorize.magenta
                end
              else
                if method.value.last.includes?('(')
                  io << method.value[0...-2].map(&.colorize.blue).join("::")
                  io << (method.instance? ? '#' : '.')
                  io << method.value[-2].colorize.magenta
                  io << method.value.last
                else
                  io << method.value[0...-1].map(&.colorize.blue).join("::")
                  io << (method.instance? ? '#' : '.')
                  io << method.value.last.colorize.magenta
                end
              end

              io << "\n\n"
            end
          else
            result.each do |object|
              def_source_for object
              case kind
              when .module? then io << "module ".colorize.red
              when .class?  then io << "class ".colorize.red
              when .struct? then io << "struct ".colorize.red
              when .enum?   then io << "enum ".colorize.red
              when .alias?  then io << "alias ".colorize.red
              end

              io << object.value.map(&.colorize.blue).join("::")
              io << "\n\n"
            end
          end
        end
      end

      stdout.puts str.chomp
    end

    private def resolve_type(type : Models::Type, names : Array(String)) : Models::Type?
      return nil unless type.types?

      matches = Fzy.search(names[0], type.types.map &.name)
      p! matches
      if matches.any? { |m| m.value == names[0] }
        if names.size - 1 != 0
          return resolve_type type, names[1..]
        end

        return type.types.find! { |t| t.name == names[0] }
      end
    end

    private macro def_source_for(name)
        if source = {{name.id}}.source
          io << "# #{source.file}:#{source.line}\n".colorize.light_gray
        else
          io << "# (top level)\n".colorize.light_gray
        end
      end
  end
end
