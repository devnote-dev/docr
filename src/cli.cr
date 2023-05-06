require "cling"
require "colorize"

require "./cli/*"
require "./docr"

Colorize.on_tty_only!

module Docr
  BUILD_DATE = {% if flag?(:win32) %}
                  {{ `powershell.exe -NoProfile Get-Date -Format "yyyy-MM-dd"`.stringify.chomp }}
                {% else %}
                  {{ `date +%F`.stringify.chomp }}
                {% end %}
  BUILD_HASH = {{ `git rev-parse HEAD`.stringify[0...8] }}
end

begin
  Docr::CLI.new.execute ARGV
rescue Docr::SystemExit
end
