require "cling"
require "colorize"

require "./cli/*"
require "./docr"

Colorize.on_tty_only!

begin
  Docr::CLI.new.execute ARGV
rescue Docr::SystemExit
end
