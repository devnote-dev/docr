module Docr::Formatters
  class Signature
    include Base

    private getter io : IO
    private getter? locations : Bool

    def self.format(io : IO, type : Redoc::Library | Redoc::Type, includes : Array(String),
                    locations : Bool) : Nil
      new(io, includes, locations).format(type)
    end

    private def initialize(@io : IO, includes : Array(String), @locations : Bool)
      apply includes
    end

    private def format_namespace(type : Redoc::Namespace) : Nil
      {% for type in %w[constants modules classes structs enums aliases annotations] %}
        if {{type.id}}? && !type.{{type.id}}.empty?
          format type.{{type.id}}[0]

          if type.{{type.id}}.size > 1
            type.{{type.id}}.skip(1).each do |%type|
              {% unless type == "constants" %}io << '\n'{% end %}
              format %type
            end
          end

          io << '\n'
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
      end

      Default.signature io, type, true, false
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
        end

        Default.signature io, type, true, true
        format_namespace type

        if defs? && !type.class_methods.empty?
          type.class_methods.each do |method|
            io << '\n' if locations?
            format method, true
          end
        end

        {% unless type == "Module" %}
          if defs? && !type.constructors.empty?
            type.constructors.each do |method|
              io << '\n' if locations?
              format method, true
            end
          end
        {% end %}

        if defs? && !type.instance_methods.empty?
          type.instance_methods.each do |method|
            io << '\n' if locations?
            format method
          end
        end

        if macros? && !type.macros.empty?
          type.macros.each do |method|
            io << '\n' if locations?
            format method
          end
        end
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
      end

      Default.signature io, type, true, true

      type.constants.each do |const|
        Default.signature io, const, true, false
      end
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
      end

      Default.signature io, type, true, nil
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
      end

      Default.signature io, type, true, false
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
      end

      Default.signature io, type, true, nil
    end
  end
end
