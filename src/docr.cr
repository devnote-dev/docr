require "cling"
require "colorize"
require "crest"
require "file_utils"
require "fzy"
require "json"
require "redoc"
require "yaml"

require "./commands/base"
require "./commands/*"
# require "./formatters/*"
require "./library"
require "./resource"

Colorize.on_tty_only!

module Docr
  VERSION = "1.0.0-alpha"

  BUILD_DATE = {% if flag?(:win32) %}
                 {{ `powershell.exe -NoProfile Get-Date -Format "yyyy-MM-dd"`.stringify.chomp }}
               {% else %}
                 {{ `date +%F`.stringify.chomp }}
               {% end %}
  BUILD_HASH = {{ `git rev-parse HEAD`.stringify[0...8] }}

  class App < Commands::Base
    def setup : Nil
      @name = "main"
      @description = <<-DESC
        A CLI tool for searching Crystal documentation with version support
        for the standard library documentation and documentation for third-party
        libraries (or shards).
        DESC

      add_usage "docr <command> [options] <arguments>"

      add_command Commands::About.new
      # add_command Commands::Meta.new
      add_command Commands::List.new
      add_command Commands::Info.new
      add_command Commands::Search.new
      add_command Commands::Add.new
      # add_command Commands::Check.new
      add_command Commands::Update.new
      add_command Commands::Remove.new
      add_command Commands::Env.new
      add_command Commands::Version.new
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout.puts help_template
    end
  end

  class SystemExit < Exception
  end
end
