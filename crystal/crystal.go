package crystal

type TopLevel struct {
	Program Type `json:"program"`
}

type Type struct {
	Name            string        `json:"name"`
	FullName        string        `json:"full_name"`
	Summary         string        `json:"summary"`
	Doc             string        `json:"doc"`
	Kind            string        `json:"kind"`
	Abstract        bool          `json:"abstract"`
	Program         bool          `json:"program"`
	Enum            bool          `json:"enum"`
	Alias           bool          `json:"alias"`
	Const           bool          `json:"const"`
	Locations       []*Location   `json:"locations"`
	Aliased         string        `json:"aliased,omitempty"`
	SuperClass      *SuperClass   `json:"superclass,omitempty"`
	Constants       []*Constant   `json:"constants,omitempty"`
	Ancestors       []*SuperClass `json:"ancestors,omitempty"`
	Included        []*SuperClass `json:"included_modules,omitempty"`
	Extended        []*SuperClass `json:"extended_modules,omitempty"`
	Constructors    []*Definition `json:"constructors,omitempty"`
	ClassMethods    []*Definition `json:"class_methods,omitempty"`
	InstanceMethods []*Definition `json:"instance_methods,omitempty"`
	Macros          []*Definition `json:"macros,omitempty"`
	Types           []*Type       `json:"types,omitempty"`
}

type Location struct {
	File string `json:"filename"`
	Line int    `json:"line_number"`
}

type SuperClass struct {
	Name     string `json:"name"`
	FullName string `json:"full_name"`
	Kind     string `json:"kind"`
}

type Constant struct {
	Name    string `json:"name"`
	Value   string `json:"value"`
	Summary string `json:"summary,omitempty"`
	Doc     string `json:"doc,omitempty"`
}

type Definition struct {
	Name     string    `json:"name"`
	Args     string    `json:"args_string,omitempty"`
	Summary  string    `json:"summary,omitempty"`
	Doc      string    `json:"doc,omitempty"`
	HTMLID   string    `json:"html_id"`
	Abstract bool      `json:"abstract"`
	Alias    bool      `json:"alias"`
	Aliased  string    `json:"aliased,omitempty"`
	Enum     bool      `json:"enum"`
	Location *Location `json:"location"`
	Def      *struct {
		Visibility string `json:"visibility"`
	} `json:"def,omitempty"`
}
