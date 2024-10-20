<p>
  <h3 align="center">docr | doc-cr | /ˈdɒ·kur/</h3>
  <p align="center">A CLI tool for searching Crystal documentation</p>
</p>

## Installation

See the [releases page](https://github.com/devnote-dev/docr/releases/latest) for available binaries.

### Windows

```
scoop bucket add docr https://github.com/devnote-dev/docr
scoop install docr
```

### From Source

Crystal v1.10.0 or above is required to build Docr.

```sh
git clone https://github.com/devnote-dev/docr
cd docr
shards build
```

## Usage

By default Docr comes with no libraries, but you can easily import the standard library documentation using `docr add crystal`. Docr will default to the latest available version, but you can specify the version as a second argument. You can also import shard documentation by specifying the source URL in one of the following formats:

- docr add https://github.com/user/repo
- docr add github.com/user/repo
- docr add github:user/repo
- docr add gh:user/repo

The following shorthands are supported for sources:

- github: / gh:
- gitlab: / gl:
- bitbucket: / bb:
- codeberg: / cb:
- srht:

> ![IMPORTANT]
> Only GitHub, GitLab, BitBucket, Codeberg and Source Hut are supported sources. Bare repositories are not supported.

After importing the libraries you want, you can simply lookup or search whatever you want! Use the `docr search` command to search for all types and symbols matching the query, and the `docr info` command to get direct information about a specified type or symbol:

![demo_4](/assets/demo_4.png)

Both the `info` and `search` commands support Crystal path syntax for queries, meaning the following commands are valid:

- `docr info raise`
- `docr info ::puts`
- `docr info JSON.parse`
- `docr info ::JSON::Any#as_s`

However, the following commands _are not_ valid:

- `docr info to_s.nil?`
- `docr info IO.Memory`
- `docr info JSON::parse`
- `docr info JSON#Any.as_s`

TODO: complete 'info' & 'search' headers

## Contributing

1. Fork it (https://github.com/devnote-dev/docr/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Devonte](https://github.com/devnote-dev) - creator and maintainer

This repository is managed under the Mozilla Public License v2.

© 2023-present devnote-dev
