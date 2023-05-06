require "cling"
require "colorize"

require "./commands/*"
require "./docr"

Colorize.on_tty_only!

module Docr
  BUILD_DATE = {% if flag?(:win32) %}
                  {{ `powershell.exe -NoProfile Get-Date -Format "yyyy-MM-dd"`.stringify.chomp }}
                {% else %}
                  {{ `date +%F`.stringify.chomp }}
                {% end %}
  BUILD_HASH = {{ `git rev-parse HEAD`.stringify[0...8] }}

  class CLI < Commands::Base
    def setup : Nil
      @name = "main"
      @description = <<-DESC
        A CLI tool for searching Crystal documentation with version support
        for the standard library documentation and documentation for third-party
        libraries (or shards).
        DESC

      add_usage "docr <command> [options] <arguments>"

      add_command Commands::Version.new
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts help_template
    end
  end

  class SystemExit < Exception
  end
end

begin
  Docr::CLI.new.execute ARGV
rescue Docr::SystemExit
end
