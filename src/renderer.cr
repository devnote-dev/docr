module Docr
  class Renderer < Markd::Renderer
    def heading(node : Markd::Node, entering : Bool) : Nil
      level = node.data["level"].as(Int32)

      if entering
        literal "\n"

        if level == 1
          literal "\e[45;97m  "
        else
          literal "\e[34m"
          literal "#" * level
          literal " "
        end
      else
        literal "  " if level == 1
        literal "\e[0m\n\n"
      end
    end

    def code(node : Markd::Node, __) : Nil
      literal(String.build do |io|
        Colorize.with.back(236).fore(203).surround(io) do
          io << ' ' << node.text << ' '
        end
      end)
    end

    def code_block(node : Markd::Node, __) : Nil
      literal(String.build do |io|
        io << '\n'
        Colorize.with.fore(244).surround(io) do
          node.text.each_line do |line|
            io << "  " << line << '\n'
          end
        end
        io << '\n'
      end)
    end

    def thematic_break(node : Markd::Node, __) : Nil
      literal "\n————————————\n".colorize.dark_gray.to_s
    end

    def block_quote(node : Markd::Node, entering : Bool) : Nil
      # literal "┃ ".colorize.dark_gray.to_s if entering
      literal "\n" unless entering
    end

    def list(node : Markd::Node, entering : Bool) : Nil
      literal "\n" unless entering
    end

    def item(node : Markd::Node, entering : Bool) : Nil
      literal "• " if entering
    end

    def link(node : Markd::Node, __) : Nil
    end

    def image(node : Markd::Node, __) : Nil
      literal node.text
    end

    def html_block(node : Markd::Node, __) : Nil
      literal "\n"
      literal node.text
      literal "\n"
    end

    def html_inline(node : Markd::Node, __) : Nil
      literal "\n"
    end

    def paragraph(node : Markd::Node, entering : Bool) : Nil
      literal "\n" unless entering
    end

    def emphasis(node : Markd::Node, __) : Nil
      literal node.text.colorize.italic.to_s
    end

    def soft_break(node : Markd::Node, __) : Nil
      literal " "
    end

    def line_break(node : Markd::Node, __) : Nil
      literal "\n"
    end

    def strong(node : Markd::Node, __) : Nil
      literal node.text.colorize.bold.to_s
    end

    def strikethrough(node : Markd::Node, __) : Nil
      literal node.text.colorize.strikethrough.to_s
    end

    def text(node : Markd::Node, __) : Nil
      literal node.text
    end

    # Markd::Renderer isn't reusable by default...
    def render(document : Markd::Node) : String
      str = super
      @output_io = String::Builder.new
      str
    end
  end
end
