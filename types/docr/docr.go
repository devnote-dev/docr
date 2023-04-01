package docr

type Tree struct {
	Modules   []Module   `json:"modules"`
	Constants []Constant `json:"constants"`
	Aliases   []Alias    `json:"aliases"`
	Enums     []Enum     `json:"enums"`
}

type Module struct {
	Name         string       `json:"name"`
	Summary      string       `json:"summary"`
	Description  string       `json:"description"`
	Locations    []Location   `json:"locations"`
	Included     []SuperClass `json:"included"`
	Extended     []SuperClass `json:"extended"`
	ClassMethods []Definition `json:"class_methods"`
}

type Constant struct {
	Name        string `json:"name"`
	Value       string `json:"value"`
	Summary     string `json:"summary"`
	Description string `json:"doc"`
}

type Alias struct {
	Name     string   `json:"name"`
	Aliased  string   `json:"aliased"`
	Location Location `json:"location"`
}

type Enum struct {
	Name    string   `json:"name"`
	Members []string `json:"members"`
}

type Location struct {
	File string `json:"filepath"`
	Line int    `json:"line_number"`
}

type SuperClass struct {
	Name string
	Kind string
}

type Definition struct {
	Name        string   `json:"name"`
	Args        string   `json:"args_string,omitempty"`
	Summary     string   `json:"summary,omitempty"`
	Description string   `json:"doc,omitempty"`
	Abstract    bool     `json:"abstract"`
	Location    Location `json:"location"`
}
