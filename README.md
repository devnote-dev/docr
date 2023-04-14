# Docr

`docr` is a tool for searching Crystal API and shards documentation from the command line.

![demo_1](/assets/demo_1.png)

## Installation

Currently Docr can only built from source (releases coming soon). Go 1.18 or above is required to build this application.

```sh
git clone https://github.com/devnote-dev/docr
cd docr
go get

scripts/build.cmd # for windows
scripts/build.sh # for linux/darwin
```

## Usage

By default, Docr comes with no libraries, but you can easily import the standard library documentation using `docr update`. This command will search for the `crystal` executable on your system and import that version of the API documentation. If the executable isn't found, it defaults to the latest available Crystal release. If you want to import the standard library directly or a specific version, you can do so with the `docr add crystal <version>` command (also accepts "latest" as a version).

![demo_2](/assets/demo_2.png)

You can also import third-party libraries (or shards) using the `docr add` command:

![demo_3](/assets/demo_3.png)

After importing the libraries you want, you can simply lookup or search whatever you want! Use the `docr search` command to search for all types and symbols matching the query, and the `docr info` command to get direct information about a specified type or symbol:

![demo_4](/assets/demo_4.png)

Both the `info` and `search` commands support Crystal path syntax for queries, so `docr info JSON::Any.as_s` is a perfectly valid query, as is `docr info JSON::Any as_s`, but _not_ `docr info JSON Any as_s`. This is because the first argument is parsed as the type path, and the second argument (if specified) is parsed as the symbol to search for. You can also use `#` in place of `.` for type-symbol names.

## Contributing

1. Fork it (https://github.com/devnote-dev/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

* [Devonte W](https://github.com/devnote-dev) - creator and maintainer

This repository is managed under the Mozilla Public License v2.

© 2023 devnote-dev
