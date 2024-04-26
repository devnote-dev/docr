module Docr::Commands
  abstract class Base < Cling::Command
    def initialize
      super

      @inherit_options = true
      @debug = false
      add_option "debug", description: "print debug information"
      add_option "no-color", description: "disable ansi color codes"
      add_option 'h', "help", description: "get help information"
    end

    def help_template : String
      String.build do |io|
        io << "Usage".colorize.blue << '\n'
        @usage.each do |use|
          io << "• " << use << '\n'
        end
        io << '\n'

        unless @children.empty?
          io << "Commands".colorize.blue << '\n'
          max_size = 4 + @children.keys.max_of &.size

          @children.each do |name, command|
            io << "• " << name.colorize.bold
            if summary = command.summary
              io << " " * (max_size - name.size)
              io << summary
            end
            io << '\n'
          end

          io << '\n'
        end

        io << "Options".colorize.blue << '\n'
        max_size = 4 + @options.each.max_of { |name, opt| name.size + (opt.short ? 2 : 0) }

        @options.each do |name, option|
          if short = option.short
            io << '-' << short << ", "
          end
          io << "--" << name

          if description = option.description
            name_size = name.size + (option.short ? 4 : 0)
            io << " " * (max_size - name_size)
            io << description
          end
          io << '\n'
        end
        io << '\n'

        io << "Description".colorize.blue << '\n'
        io << @description
      end
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Bool
      @debug = true if options.has? "debug"
      Colorize.enabled = false if options.has? "no-color"

      if options.has? "help"
        stdout.puts help_template

        false
      else
        true
      end
    end

    def debug(data : _) : Nil
      return unless @debug
      stdout << "(#) ".colorize.bold << data << '\n'
    end

    def info(data : _) : Nil
      stdout << "(i) ".colorize.blue << data << '\n'
    end

    def warn(data : _) : Nil
      stdout << "(!) ".colorize.yellow << data << '\n'
    end

    def error(data : _) : Nil
      stdout << "(!) ".colorize.red << data << '\n'
    end

    protected def system_exit : NoReturn
      raise SystemExit.new
    end

    def on_error(ex : Exception)
      raise ex if ex.is_a? SystemExit

      if ex.is_a? Cling::CommandError
        error ex.to_s
        error "See '#{"docr --help".colorize.blue}' for more information"
        return
      end

      error "Unexpected exception:"
      error ex
      error "Please report this on the Docr GitHub issues:"
      error "https://github.com/devnote-dev/docr/issues"

      return unless @debug
      debug "loading stack trace..."

      stack = ex.backtrace || %w[???] # slow, needs investigating
      stack.each { |line| debug " " + line }
    end

    def on_missing_arguments(args : Array(String))
      command = "docr #{self.name} --help".colorize.blue
      error "Missing required argument#{"s" if args.size > 1}:"
      error " #{args.join(", ")}"
      error "See '#{command}' for more information"
      system_exit
    end

    def on_unknown_arguments(args : Array(String))
      command = %(docr #{self.name == "main" ? "" : self.name + " "}--help).colorize.blue
      error "Unexpected argument#{"s" if args.size > 1} for this command:"
      error " #{args.join ", "}"
      error "See '#{command}' for more information"
      system_exit
    end

    def on_unknown_options(options : Array(String))
      command = %(docr #{self.name == "main" ? "" : self.name + " "}--help).colorize.blue
      error "Unexpected option#{"s" if options.size > 1} for this command:"
      error " #{options.join ", "}"
      error "See '#{command}' for more information"
      system_exit
    end
  end
end
