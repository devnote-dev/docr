module Docr::Commands
  class Help < Base
    def setup : Nil
      @name = "help"
      @summary = "get help information for a command"

      add_argument "command"
    end

    def pre_run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      Colorize.enabled = false if options.has? "no-color"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      main = parent.as(Cling::Command)
      command = arguments.get?("command").try &.as_s

      if command && command != "help"
        main.execute [command, "--help"]
      else
        main.run arguments, options
      end
    end
  end
end
