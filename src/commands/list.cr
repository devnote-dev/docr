module Docr::Commands
  class List < Base
    def setup : Nil
      @name = "list"
      @summary = "lists imported libraries"
      @description = "Lists imported libraries, including their versions."
    end

    def run(arguments : Cling::Arguments, options : Cling::Options) : Nil
      stdout << String.build do |io|
        libs = Library.list_all
        return error "no libraries have been installed" if libs.empty?

        libs.each do |name, versions|
          io << name << '\n'
          versions.each do |version|
            io << "• "
            io << 'v' if version[0].ascii_number?
            io << version << '\n'
          end
          io << '\n'
        end
      end.chomp
    end
  end
end
