module Docr::ENV
  extend self

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

  def has_libraries? : Bool
    Dir.exists? LIBRARY_DIR
  end

  def has_library?(name : String) : Bool
    Dir.exists? LIBRARY_DIR / name
  end

  def get_libraries : Hash(String, Array(String))
    libs = {} of String => Array(String)

    Dir.each_child(LIBRARY_DIR) do |child|
      next unless File.directory?(LIBRARY_DIR / child)

      if child == "crystal"
        libs["crystal"] = Dir.children(LIBRARY_DIR / "crystal")
      else
        versions = Dir.children(LIBRARY_DIR / child)
        puts versions
        libs[child] = versions
      end
    end

    libs
  end

  def get_library(name : String, version : String? = nil) : Models::TopLevel
    versions = get_versions_for name
    if version
      raise "version #{version} not found" unless versions.includes? version
    end

    version ||= versions.sort.first
    path = LIBRARY_DIR / name / version / "index.json"

    # TODO
    # if name == "crystal"
    #   path = LIBRARY_DIR / "crystal" / (version + ".json")
    # else
    #   path = LIBRARY_DIR / name / version / "index.json"
    # end

    File.open(path) do |file|
      Models::TopLevel.from_json file.gets_to_end
    end
  end

  def get_versions_for(name : String) : Array(String)
    Dir.children(LIBRARY_DIR / name)
  end

  def remove_library(name : String, version : String? = nil) : Nil
    path = LIBRARY_DIR / name

    if version
      path /= version

      File.delete(path / "index.json")
      Dir.delete path if Dir.empty? path
    else
      # TODO: may require rm-rf
      Dir.delete path
    end
  end
end
