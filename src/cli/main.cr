module Docr
  class CLI < BaseCommand
    def setup : Nil
      @name = "main"
      @description = <<-DESC
        A CLI tool for searching Crystal documentation with version support
        for the standard library documentation and documentation for third-party
        libraries (or shards).
        DESC

      add_usage "docr <command> [options] <arguments>"
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts help_template
    end
  end
end
