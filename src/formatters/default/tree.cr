module Docr::Formatters
  class Default
    include Base

    private getter io : IO
    private getter indent : Int32 = 0
    private getter? locations : Bool

    def self.tree(io : IO, type : Redoc::Library | Redoc::Type, includes : Array(String),
                  locations : Bool) : Nil
      new(io, includes, locations).format(type)
    end

    private def initialize(@io : IO, includes : Array(String), @locations : Bool)
      apply includes
    end

    private def indent(value : Int32) : Nil
      @indent += value
    end

    private def format_namespace(type : Redoc::Namespace) : Nil
      newline = false

      {% for type in %w[constants modules classes structs enums aliases annotations] %}
        if {{type.id}}? && !type.{{type.id}}.empty?
          newline = true
          io << (" " * indent)
          format type.{{type.id}}[0]

          if type.{{type.id}}.size > 1
            type.{{type.id}}.skip(1).each do |%type|
              {% unless type == "constants" %}io << '\n'{% end %}
              io << (" " * indent)
              format %type
            end
          end

          io << '\n' if newline
          newline = false
        end
      {% end %}
    end

    def format(type : Redoc::Library) : Nil
      io << "# Top Level Namespace\n\n".colorize.dark_gray

      if defs? && !type.methods.empty?
        type.methods.each do |method|
          format method
        end
        io << '\n'
      end

      if macros? && !type.macros.empty?
        type.macros.each do |method|
          format method
        end
        io << '\n'
      end

      format_namespace type
    end

    def format(type : Redoc::Const) : Nil
      return unless constants?

      if locations?
        if type.top_level?
          io << "# top level namespace\n".colorize.dark_gray
        else
          io << "(cannot resolve location)\n".colorize.dark_gray
        end
        io << (" " * indent)
      end

      Default.signature io, type, false, false
    end

    {% for type, guard in {Module: :modules?, Class: :classes?, Struct: :structs?} %}
      def format(type : Redoc::{{type.id}}) : Nil
        return unless {{guard.id}}

        if locations?
          if url = type.locations[0]?.try(&.url)
            Colorize.with.dark_gray.surround(io) do
              io << "# " << url << '\n'
            end
          else
            io << "(cannot resolve location)\n".colorize.dark_gray
          end
          io << (" " * indent)
        end

        Default.signature io, type, false, true
        indent 2

        has_includes = has_defs = false

        unless type.includes.empty?
          has_includes = true

          type.includes.each do |ref|
            io << (" " * indent)
            io << "include ".colorize.red
            io << Default.format_path ref.full_name, :magenta
            io << '\n'
          end
        end

        unless type.extends.empty?
          io << '\n' if has_includes
          has_includes = true

          type.extends.each do |ref|
            io << (" " * indent)
            io << "extend ".colorize.red

            if ref.full_name == type.full_name
              io << "self".colorize.blue
            else
              io << Default.format_path ref.full_name, :magenta
            end

            io << '\n'
          end
        end

        io << '\n' if has_includes
        format_namespace type

        if defs? && !type.class_methods.empty?
          has_defs = true

          type.class_methods.each do |method|
            io << '\n' if locations?
            io << (" " * indent)
            format method, true
          end
        end

        {% unless type == "Module" %}
          if defs? && !type.constructors.empty?
            io << '\n' if has_defs
            has_defs = true

            type.constructors.each do |method|
            io << '\n' if locations?
            io << (" " * indent)
              format method, true
            end
          end
        {% end %}

        if defs? && !type.instance_methods.empty?
          io << '\n' if has_defs
          has_defs = true

          type.instance_methods.each do |method|
            io << '\n' if locations?
            io << (" " * indent)
            format method
          end
        end

        if macros? && !type.macros.empty?
          io << '\n' if has_defs

          type.macros.each do |method|
            io << '\n' if locations?
            io << (" " * indent)
            format method
          end
        end

        indent -2
        io << (" " * indent) << "end\n".colorize.red
      end
    {% end %}

    def format(type : Redoc::Enum) : Nil
      return unless enums?

      if locations?
        if url = type.locations[0]?.try(&.url)
          Colorize.with.dark_gray.surround(io) do
            io << "# " << url << '\n'
          end
        else
          io << "(cannot resolve location)\n".colorize.dark_gray
        end
        io << (" " * indent)
      end

      Default.signature io, type, false, true
      indent 2

      type.constants.each do |const|
        io << (" " * indent)
        Default.signature io, const, true, false
      end

      indent -2
      io << (" " * indent) << "end\n".colorize.red
    end

    def format(type : Redoc::Alias) : Nil
      return unless aliases?

      if locations?
        if url = type.locations[0]?.try(&.url)
          Colorize.with.dark_gray.surround(io) do
            io << "# " << url << '\n'
          end
        else
          io << "(cannot resolve location)\n".colorize.dark_gray
        end
        io << (" " * indent)
      end

      Default.signature io, type, true, false
    end

    def format(type : Redoc::Annotation) : Nil
      return unless annotations?

      if locations?
        if url = type.locations[0]?.try(&.url)
          Colorize.with.dark_gray.surround(io) do
            io << "# " << url << '\n'
          end
        else
          io << "(cannot resolve location)\n".colorize.dark_gray
        end
        io << (" " * indent)
      end

      Default.signature io, type, false, nil
    end

    def format(type : Redoc::Def, with_self : Bool = false) : Nil
      return unless defs?

      if locations?
        if url = type.location.try(&.url)
          Colorize.with.dark_gray.surround(io) do
            io << "# " << url << '\n'
          end
        else
          io << "(cannot resolve location)\n".colorize.dark_gray
        end
        io << (" " * indent)
      end

      Default.signature io, type, false, with_self
    end

    def format(type : Redoc::Macro) : Nil
      return unless macros?

      if locations?
        if url = type.location.try(&.url)
          Colorize.with.dark_gray.surround(io) do
            io << "# " << url << '\n'
          end
        else
          io << "(cannot resolve location)\n".colorize.dark_gray
        end
        io << (" " * indent)
      end

      Default.signature io, type, false, nil
    end
  end
end
