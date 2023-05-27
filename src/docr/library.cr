module Docr
  class Library
    CACHE_DIR = begin
      {% if flag?(:win32) %}
        Path[::ENV["LOCALAPPDATA"]] / "docr"
      {% else %}
        if cache = ::ENV["XDG_CACHE_HOME"]?
          Path[cache] / "docr"
        else
          Path.home / ".config" / "docr"
        end
      {% end %}
    end

    LIBRARY_DIR = begin
      {% if flag?(:win32) %}
        Path[::ENV["APPDATA"]] / "docr"
      {% else %}
        if data = ::ENV["XDG_DATA_HOME"]?
          Path[data] / "docr"
        else
          Path.home / ".local" / "share" / "docr"
        end
      {% end %}
    end

    class Error < Exception
    end

    getter name : String
    getter version : String
    getter data : Models::TopLevel

    def initialize(@name : String, @version : String, @data : Models::TopLevel)
    end

    def self.has_libraries? : Bool
      Dir.exists? LIBRARY_DIR
    end

    def self.exists?(name : String) : Bool
      Dir.exists? LIBRARY_DIR / name
    end

    def self.list : Hash(String, Array(String))
      libs = {} of String => Array(String)

      Dir.each_child(LIBRARY_DIR) do |child|
        next unless File.directory?(LIBRARY_DIR / child)

        if child == "crystal"
          libs["crystal"] = Dir.children(LIBRARY_DIR / "crystal").map &.strip(".json")
        else
          versions = Dir.children(LIBRARY_DIR / child)
          libs[child] = versions
        end
      end

      libs
    end

    def self.fetch(name : String, version : String? = nil) : Library
      versions = get_versions_for name
      if version
        raise Library::Error.new "version #{version} not found" unless versions.includes? version
      end

      version ||= versions.sort.last
      path = LIBRARY_DIR / name / version
      path /= "index.json" unless name == "crystal"
      data = Models::TopLevel.from_json File.read(path)

      Library.new(name, version, data)
    end

    def self.get_versions_for(name : String) : Array(String)
      Dir.children(LIBRARY_DIR / name)
    rescue File::NotFoundError
      Dir.mkdir_p(LIBRARY_DIR / name)
      [] of String
    end

    def delete(all_versions : Bool) : Nil
      path = LIBRARY_DIR / @name

      if all_versions
        FileUtils.rm_rf path
      else
        path /= @version

        File.delete(path / "index.json")
        Dir.delete path if Dir.empty? path
      end
    end
  end
end
