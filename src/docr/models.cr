module Docr::Models
  struct Class
    include JSON::Serializable

    getter name : String
    getter full_name : String
    getter kind : String
  end

  struct Constant
    include JSON::Serializable

    getter name : String
    getter value : String
    getter summary : String?
    getter doc : String?
  end

  struct Def
    include JSON::Serializable

    getter name : String
    @[JSON::Field(key: "args_string")]
    getter args : String?
    getter summary : String?
    getter doc : String?
    getter html_id : String
    getter? abstract : Bool = false
    getter? alias : Bool = false
    getter? enum : Bool = false
    getter aliased : String?
    getter location : Location?
  end

  struct Location
    include JSON::Serializable

    @[JSON::Field(key: "filename")]
    getter file : String
    @[JSON::Field(key: "line_number")]
    getter line : Int32
    getter url : String
  end

  struct TopLevel
    include JSON::Serializable

    getter body : String
    getter program : Type
  end

  struct Type
    include JSON::Serializable

    getter name : String
    getter full_name : String
    getter summary : String?
    getter doc : String?
    getter kind : String
    getter? abstract : Bool
    getter? program : Bool
    getter? enum : Bool
    getter? alias : Bool
    getter? const : Bool
    getter locations : Array(Location)
    getter aliased : String?
    getter superclass : Class?
    getter constants : Array(Constant)?
    getter ancestors : Array(Class)?
    getter included : Array(Class)?
    getter extended : Array(Class)?
    getter constructors : Array(Def)?
    getter class_methods : Array(Def)?
    getter instance_methods : Array(Def)?
    getter macros : Array(Def)?
    getter types : Array(Type)?
  end
end
