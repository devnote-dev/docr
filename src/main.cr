require "./docr"

begin
  Docr::App.new.execute ARGV
rescue Docr::SystemExit
  exit 1
end
