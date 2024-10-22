module Docr::Library
  def self.exists?(name : String, version : String? = nil) : Bool
    if version
      File.exists?(LIBRARY_DIR / name / (version + ".json"))
    else
      Dir.exists?(LIBRARY_DIR / name) && !get_versions_for(name).empty?
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
  rescue
    Dir.mkdir_p LIBRARY_DIR

    libs.not_nil! # ameba:disable Lint/NotNil
  end

  def self.get_versions_for(name : String) : Array(String)
    versions = [] of String

    Dir.each_child(LIBRARY_DIR / name) do |child|
      next unless child.ends_with? ".json"
      versions << child.chomp ".json"
    end

    zero = SemanticVersion.new(0, 0, 0)

    versions.sort_by! { |v| SemanticVersion.parse(v) rescue zero }
  end

  def self.get(name : String, version : String) : Redoc::Library
    File.open(LIBRARY_DIR / name / (version + ".json")) do |file|
      Redoc::Library.from_json file
    end
  end

  def self.get_source(name : String) : String
    File.read LIBRARY_DIR / name / "SOURCE"
  end

  def self.delete(name : String, version : String?) : Nil
    if version
      File.delete(LIBRARY_DIR / name / (version + ".json"))
    else
      FileUtils.rm_rf(LIBRARY_DIR / name)
    end
  end
end
