module Docr::Commands
  class Search < Base
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
      add_argument "type"
      add_argument "symbol"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
      return false unless super
      return on_missing_arguments(%w[symbol]) unless arguments.has?("library")

      library = arguments.get("library").as_s
      type = arguments.get?("type").try &.as_s
      symbol = arguments.get?("symbol").try &.as_s

      if library.matches? /\A[a-z0-9_-]+\z/
        if type.nil?
          arg = Cling::Argument.new("symbol")
          arg.value = arguments.get("library")
          arguments.hash["symbol"] = arg
          arguments.hash["library"].value = Cling::Value.new("crystal")
        end
      else
        if type.nil?
          arguments.hash["type"] = Cling::Argument.new("type")
        end

        if symbol.nil?
          arg = Cling::Argument.new("symbol")
          arg.value = arguments.get?("type")
          arguments.hash["symbol"] = arg
        end

        arguments.hash["type"].value = arguments.get("library")
        arguments.hash["library"].value = Cling::Value.new("crystal")
      end

      true
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      lib_name = arguments.get("library").as_s
      type = arguments.get?("type").try &.as_s
      symbol = arguments.get?("symbol").try &.as_s

      debug "library: #{lib_name.inspect}"
      debug "type: #{type.inspect}"
      debug "symbol: #{symbol.inspect}"

      query = Docr::Search::Query.parse [type, symbol].reject(Nil)
      versions = Library.get_versions_for lib_name

      if versions.empty?
        format = "docr add #{lib_name} <source>".colorize.blue
        error "no documentation is available for this library"
        error "to import a version of this library, run '#{format}'"
        return
      end

      # TODO: support --version

      library = Library.fetch lib_name
      data = library.data.program

      unless query.types.empty?
        data = resolve_type data, query.types
        if data.nil? && lib_name != "crystal"
          data = resolve_type library.data.program.types.not_nil![0], query.types
        end

        if data.nil?
          return error "could not resolve types or namespaces for that symbol"
        end
      end

      results = Docr::Search.filter_types data, query.symbol
      if results.empty?
        return error "no documentation found for symbol '#{query.symbol}'"
      end

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
                  io << '.'
                  io << method.value[1].colorize.magenta
                end
              else
                if method.value.last.includes?('(')
                  io << method.value[0...-2].map(&.colorize.blue).join("::")
                  io << '.'
                  io << method.value[-2].colorize.magenta
                  io << method.value.last
                else
                  io << method.value[0...-1].map(&.colorize.blue).join("::")
                  io << '.'
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

    private def resolve_type(top : Models::Type, names : Array(String)) : Models::Type?
      return nil unless types = top.types

      types.each do |type|
        if type.name == names[0] || type.full_name == names[0]
          if names.size - 1 != 0
            return resolve_type type, names[1..]
          end

          return type
        end
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
