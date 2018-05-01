# Genesis

[![SPM](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=for-the-badge)](https://swift.org/package-manager)
[![Git Version](https://img.shields.io/github/release/yonaskolb/Genesis.svg?style=for-the-badge)](https://github.com/yonaskolb/Genesis/releases)
[![Build Status](https://img.shields.io/circleci/project/github/yonaskolb/Genesis.svg?style=for-the-badge)](https://circleci.com/gh/yonaskolb/Genesis)
[![license](https://img.shields.io/github/license/yonaskolb/Genesis.svg?style=for-the-badge)](https://github.com/yonaskolb/Genesis/blob/master/LICENSE)

Genesis is a templating and scaffolding tool.

A Genesis template is a manifest of options and files written in yaml or json. Option values can be provided in [various ways](#providing-options) otherwise you will be interactively asked for inputs. Template files are written in [Stencil](https://github.com/kylef/Stencil). The list of files can make use of dynamic paths and be generated multiple times depending on the format of the input.

- ✅ Template manifests in easy to read and write **yaml or json**
- ✅ Template files written in **Stencil** templating language
- ✅ Provide **options** via ENV, command line, file or interactively
- ✅ Powerful command line **interactivity** with choices, lists and branching
- ✅ Write **dynamic** file paths

The very simple example:

```yaml
options:
  - name: project
    description: The name of the project
    question: What is the name of your project?
    required: true
    type: string
files:
  - template: project.stencil
    path: "{{ name }}.project
```

And then run like this:

```sh
$ genesis generate template.yml
What is the name of your project? MyProject
Generated files:
  MyProject.project
```

Or you can provide the required options via arguments

```sh
$ genesis generate template.yml --options name:MyProject
Generated files:
  MyProject.project
```

Much more powerful templates are possible. See more complete documentation [here](#templates)

## Installing
Make sure Xcode 9 is installed first.

#### [Mint](https://github.com/yonaskolb/mint)
```sh
$ mint install yonaskolb/genesis
```

### Make

```sh
$ git clone https://github.com/yonaskolb/Genesis.git
$ cd Genesis
$ make
```

### Swift Package Manager

**Use CLI**

```sh
$ git clone https://github.com/yonaskolb/Genesis.git
$ cd Genesis
$ swift run mint
```

**Use as dependency**

Add the following to your Package.swift file's dependencies:

```swift
.package(url: "https://github.com/yonaskolb/Genesis.git", from: "0.1.0"),
```

And then import `GenesisKit`. See [GenesisKit](#genesiskit) for more information.


## Usage

Run `genesis help` for usage instructions

```
Usage: genesis generate <templatePath> [options]

Options:
  -d, --destination <value>    Path to the directory where output will be generated. Defaults to the current directory
  -h, --help                   Show help information for this command
  -n, --non-interactive        Do not prompt for required options
  -o, --options <value>        Provide option overrides, in the format --options "option1: value 2, option2: value 2.
  -p, --option-path <value>    Path to a yaml or json file containing options
```

## Providing options
Options will be passed to the template in the following order, merging along the way, with duplicate options overriding the previous ones.

#### 1. Environment Variables
Set any environment variables before you call generate, or use already existing ones from your development environment

```
name="My Name" genesis generate template.yml
```

#### 2. Options File
Pass a path to a json or yaml file with `--option-file`
This can include more structures and complex data. For example:

```yaml
name: MyProject
targets:
  - name: MyTarget
    type: application
  - name: MyFramework
    type: framework  
```

#### 3. Options Argument
Pass specific options with `--options` like this

```
-- options "option1: value 2, option2: value 2"
```

#### 4. Interactive input
Genesis will ask you for any missing options if they are required. You can turn off interactive input with `--non-interactive`.

#### 5. Default value
Each option can have a default `value` which be used as a fallback. 

#### Missing value
If an option is required and still hasn't received a value from anywhere, generation will fail.

## Template
A genesis template is a yaml or json file that includes a list of `options` and `files`

#### Options
Options are structured input for the `Stencil` templates. They serve as documentation and allow for Genesis to interactively ask for input.

- **name**: This is the name that is referenced in the template as well as the command line
- **value**: This is the default value that will be used if none are provided. This can have Stencil tags in it
- **question**: The question that is asked when asking for input. This can have Stencil tags in it
- **description**: An extended description of the option and what it does
- **required**: Whether this option is required or not for the template to generate. If it is not provided via the command line, option file, or input, generation will fail
- **type**: This is the type of option. It defaults to `string` but can be any one of the following:
	- `string` a simple string
	- `boolean` a boolean
	- `choice` a string from a list of choices. Requires `choices` to be defined
	- `array` an array of other options. Requires `options` to be defined.
 
#### Files

- **path**: This is the path the file will be generated at. It can include `Stencil` tags to make it dynamic. This defaults to `template` if present
- **contents**: A file template string
- **template**: A path to a file template
- **context**: An optional context property path that will be passed to the template. If this resolves to an array, a file for each element will be created, using tags in `path` to differentiate them.
- **include**: Whether the file should be written. This is a Stencil if tag without the braces. For example instead of `{% if type == 'framework' %}` you would write `type == 'framework'`

Each file can have a `contents` or `template`. If neither of those are present, the file will be copied exactly as is without any content replacement.
The final path of the file will be based off `path` otherwise `template`.

## Stencil Templates
Each Stencil template has all the filters available in [StencilSwiftKit](https://github.com/SwiftGen/StencilSwiftKit), and has access to all the [options](#options). See [Stencil](https://github.com/kylef/Stencil) for more info about tags.

Small example:

```
{% if name %}
name: {{ name }}
{% end if %}
```

## GenesisKit
The library `GenesisKit` can be used to easily provide generation in your own tools.

```swift
import GenesisKit

// create a context
let context: [String: Any] = ["name": "hello"]

// create a template, either from a file or programmatically
let template = try GenesisTemplate(path: "template.yml")

// Create the generator
let generator = try TemplateGenerator(template: template)

// generate the files
let generationResult = try generator.generate(context: context, interactive: false)

// write the files to disk
try generationResult.writeFiles(path: "destination")

```

## Contributions
Pull requests and issues are welcome

## License

Genesis is licensed under the MIT license. See [LICENSE](LICENSE) for more info.
