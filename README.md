# Genesis

[![SPM](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
[![Git Version](https://img.shields.io/github/release/yonaskolb/Genesis.svg)](https://github.com/yonaskolb/Genesis/releases)
[![Build Status](https://img.shields.io/circleci/project/github/yonaskolb/Genesis.svg?style=flat)](https://circleci.com/gh/yonaskolb/Genesis)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/yonaskolb/Genesis/blob/master/LICENSE)

Genesis is a templating and scaffolding tool.

A Genesis template is a manifest of options and files written in yaml or json. Option values can be provided in [various ways](#providing-options) otherwise you will be interactivly asked for inputs. Template files are written in [Stencil](https://github.com/kylef/Stencil)

- ✅ Create **easy** to read and write templates manifest in easy to read and write yaml or json
- ✅ Write template files in **Stencil**
- ✅ **Interactively** generate templates
- ✅ Powerful file **path generation**
- ✅ Seperate **data** from templates in option files
- ✅ Powerful option **configuration** with choices, lists and branching

The very simplest of templates could look like this

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

## Installing
Make sure Xcode 9 is installed first.

### [Mint](https://github.com/yonaskolb/mint)
```sh
$ mint install yonaskolb/genesis
```

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
Options will be passed to the template in this order which each level overriding the previous

- environment variables
- `--option-file`
- `--options`
- interactive input
- option defaults

If an option is required and hasn't recieved a value from anywhere, generation will fail.

## Template
A genesic template is a yaml or json file that includes a list of `options` and `files`

### Options
Options are structured input for the `Stencil` templates. They serve as documentation and allow for Genesis to interactively ask for input.

- **name**: This is the name that is referenced in the template as well as the command line
- **value**: This is the default value that will be used if none are provided
- **question**: The question that is asked when asking for input
- **description**: An extended description of the option and what it does
- **required**: Whether this option is required or not for the template to generate. If it is not provided via the command line, option file, or input, generation will fail
- **type**: This is the type of option. It defaults to `string` but can be any one of the following:
	- `string` a simple string
	- `boolean` a boolean
	- `choice` a string from a list of choices. Requires `choices` to be defined
	- `array` an array of other options. Requires `options` to be defined.
 
### Files

- **path**: This is the path the file will be generated at. It can include `Stencil` tags to make it dynamic. This defaults to `template` if present
- **contents**: A file template string
- **template**: A path to a file template
- **context**: An optional context property path that will be passed to the template. If this resolves to an array, a file for each element will be created, using tags in `path` to differentiate them.
- **include**: Whether the file should be written. This is a Stencil if tag without the braces. For example instead of `{% if type == 'framework' %}` you would write `type == 'framework'`

Each file can have a `contents` or `template`. If neither of those are present, the file will be copied exactly as is without any content replacement.
The final path of the file will be based off `path` otherwise `template`.

### Stencil Templates
Each Stencil template will have access to all the options. If the template is with an array it will get access to only that item within the array. See [Stencil](https://github.com/kylef/Stencil) for more info about tags

```
{% if name %}
name: {{ name }}
{% end if %}
```


## Contributions
Pull requests and issues are welcome

## License

Genesis is licensed under the MIT license. See [LICENSE](LICENSE) for more info.
