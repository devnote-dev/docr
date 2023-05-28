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

    def self.exists?(name : String, version : String? = nil) : Bool
      if version
        if name == "crystal"
          Dir.exists?(LIBRARY_DIR / name / (version + ".json"))
        else
          Dir.exists?(LIBRARY_DIR / name / version)
        end
      else
        Dir.exists?(LIBRARY_DIR / name)
      end
    end

    def self.list_all : Hash(String, Array(String))
      libs = {} of String => Array(String)

      Dir.each_child(LIBRARY_DIR) do |child|
        next unless File.directory?(LIBRARY_DIR / child)
        versions = get_versions_for child
        next if versions.empty?

        libs[child] = versions
      end

      libs
    end

    def self.get_versions_for(name : String) : Array(String)
      Dir.children(LIBRARY_DIR / name).map &.sub(".json", "")
    rescue File::NotFoundError
      Dir.mkdir_p(LIBRARY_DIR / name)
      [] of String
    end

    def self.fetch(name : String, version : String? = nil) : Library
      versions = get_versions_for name
      raise Library::Error.new "no versions of #{name} imported" if versions.empty?

      if version
        raise Library::Error.new "version #{version} of #{name} not found" unless versions.includes? version
      end

      version ||= versions.sort.last
      path = LIBRARY_DIR / name / version
      path /= "index.json" unless name == "crystal"
      data = Models::TopLevel.from_json File.read(path)

      Library.new(name, version, data)
    end

    def initialize(@name : String, @version : String, @data : Models::TopLevel)
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
