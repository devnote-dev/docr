module Docr::Resource
  def self.fetch_crystal_docs(version : String) : Models::TopLevel
    res = Crest.get "https://crystal-lang.org/api/#{version}/index.json"

    Models::TopLevel.from_json res.body
  end

  def self.fetch_crystal_versions : Array(String)
    path = Library::CACHE_DIR / "versions.txt"
    import_crystal_versions unless File.exists? path

    File.read_lines(path).map(&.split(',').first)
  end

  def self.import_crystal_versions : Nil
    cache = Library::CACHE_DIR
    Dir.mkdir_p cache unless Dir.exists? cache
    FileUtils.rm_rf cache unless Dir.empty? cache

    res = Crest.get "https://crystal-lang.org/api/versions.json"
    data = JSON.parse res.body
    content = data["versions"].as_a.map do |version|
      version["name"].as_s + "," + version["url"].as_s
    end.join('\n')

    File.write(cache / "versions.txt", content)
  end

  def self.import_crystal_version(version : String) : Nil
    versions = fetch_crystal_versions
    unless versions.includes? version
      raise Library::Error.new "crystal version #{version} not available"
    end

    ver = version == "nightly" ? "master" : version
    res = Crest.get "https://crystal-lang.org/api/#{ver}/index.json"

    File.write(Library::LIBRARY_DIR / "crystal" / (version + ".json"), res.body)
  end
end
