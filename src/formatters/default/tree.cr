module Docr::Formatters
  class Default
    include Base

    private getter io : IO
    private getter indent : Int32 = 0

    def self.tree(io : IO, type : Redoc::Library | Redoc::Type, options : Cling::Options? = nil) : Nil
      new(io, options).format(type)
    end

    private def initialize(@io : IO, options : Cling::Options?)
      apply options if options
    end

    private def indent(value : Int32) : Nil
      @indent += value
    end

    private def format_namespace(type : Redoc::Namespace) : Nil
      newline = false

      {% for type in %w[constants modules classes structs enums aliases annotations] %}
        unless type.{{type.id}}.empty?
          newline = true
          io << (" " * indent)
          format type.{{type.id}}[0]

          if type.{{type.id}}.size > 1
            type.{{type.id}}.skip(1).each do |%type|
              io << '\n'
              io << (" " * indent)
              format %type
            end
          end

        io << '\n' if newline
        end
      {% end %}
    end

    def format(type : Redoc::Library) : Nil
      io << "# Top Level Namespace\n\n".colorize.dark_gray

      unless type.methods.empty?
        type.methods.each do |method|
          format method
        end
        io << '\n'
      end

      unless type.macros.empty?
        type.macros.each do |method|
          format method
        end
        io << '\n'
      end

      format_namespace type
    end

    {% for type in %w[Module Class Struct] %}
      def format(type : Redoc::{{type.id}}) : Nil
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

        unless type.class_methods.empty?
          has_defs = true

          type.class_methods.each do |method|
            io << (" " * indent)
            format method
          end
        end

        {% unless type == "Module" %}
          unless type.constructors.empty?
            io << '\n' if has_defs
            has_defs = true

            type.constructors.each do |method|
              io << (" " * indent)
              format method
            end
          end
        {% end %}

        unless type.instance_methods.empty?
          io << '\n' if has_defs
          has_defs = true

          type.instance_methods.each do |method|
            io << (" " * indent)
            format method
          end
        end

        unless type.macros.empty?
          io << '\n' if has_defs

          type.macros.each do |method|
            io << (" " * indent)
            format method
          end
        end

        indent -2
        io << (" " * indent) << "end\n".colorize.red
      end
    {% end %}

    def format(type : Redoc::Enum) : Nil
      Default.signature io, type, false, true
      indent 2

      type.constants.each do |const|
        io << (" " * indent)
        Default.signature io, const, true
      end

      indent -2
      io << (" " * indent) << "end\n".colorize.red
    end

    def format(type : Redoc::Alias) : Nil
      Default.signature io, type, true
    end

    def format(type : Redoc::Annotation) : Nil
      Default.signature io, type
    end

    def format(type : Redoc::Def) : Nil
      Default.signature io, type, false
    end

    def format(type : Redoc::Macro) : Nil
      Default.signature io, type, false
    end

    def format(type : Redoc::Type) : Nil
    end
  end
end
