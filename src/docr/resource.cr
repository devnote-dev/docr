module Docr::Resource
  def self.fetch_crystal_docs(version : String) : Models::TopLevel
    res = Crest.get "https://crystal-lang.org/api/#{version}/index.json"

    Models::TopLevel.from_json res.body
  end
end
