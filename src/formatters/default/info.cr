module Docr::Formatters
  class Default
    def self.info(io : IO, type : Redoc::Const) : Nil
      signature io, type, true, true

      if summary = type.summary
        io << "\n  " << parse_markdown(summary) << '\n'
      end

      io << "\nDefined: "
      if type.top_level?
        io << "top-level namespace\n".colorize.dark_gray
      else
        io << "(cannot resolve location)\n".colorize.dark_gray
      end

      if doc = type.doc
        io << '\n' << parse_markdown(doc) << '\n'
      end
    end

    {% for type in %w[Module Class Struct Alias Annotation] %}
      def self.info(io : IO, type : Redoc::{{type.id}}) : Nil
        signature io, type, true, true
        info_base io, type
      end
    {% end %}

    def self.info(io : IO, type : Redoc::Enum) : Nil
      signature io, type, true, true

      type.constants.each do |const|
        io << "  " << const.name.colorize.blue << " = " << const.value

        if summary = const.summary
          io << "\n  " << parse_markdown(summary) << '\n'
        end

        io << '\n'
      end

      io << "end\n".colorize.red
      info_base io, type
    end

    {% for type in %w[Def Macro] %}
      def self.info(io : IO, type : Redoc::{{type.id}}) : Nil
        signature io, type, true, nil

        if summary = type.summary
          io << "\n  " << parse_markdown summary
        end

        io << "\nDefined:"
        if loc = type.location
          io << "\n• " << loc.filename << ':' << loc.line_number << '\n'
          if url = loc.url
            Colorize.with.dark_gray.surround(io) do
              io << "  (" << url << ")\n"
            end
          end
        else
          io << " (cannot resolve location)\n".colorize.dark_gray
        end

        if doc = type.doc
          io << '\n' << parse_markdown(doc) << '\n'
        end
      end
    {% end %}

    private def self.info_base(io : IO, type : Redoc::Type) : Nil
      if summary = type.summary
        io << "\n  " << parse_markdown summary
      end

      io << "\nDefined:\n"
      type.locations.each do |loc|
        io << "• " << loc.filename << ':' << loc.line_number << '\n'
        if url = loc.url
          Colorize.with.dark_gray.surround(io) do
            io << "  (" << url << ")\n\n"
          end
        end
      end

      if doc = type.doc
        io << parse_markdown(doc) << '\n'
      end
    end

    private def self.parse_markdown(str : String) : String
      doc = Markd::Parser.parse str
      (@@renderer ||= Renderer.new Markd::Options.new).render(doc)
    end
  end
end
