# Genesis

Genesis is a templating and scaffolding tool.

## Providing Options
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

- [x] `name`: This is the name that is referenced in the template as well as the command line
- [ ] `question`: The question that is aksed when asking for input
- [ ] `description`: An extended description of the option and what it controls
- [ ] `required`: Whether this option is required or not for the template to generate. If it is not provided via the command line, option file, or input, generation will fail
- [ ] `type`: This is the type of option. It defaults to `string` but can be any one of the following:
	- `string` a simple string
	- `boolean` a boolean
	- `choice` a string for a list of choices. Requires `choices` to be defined
	- `array` an array of other options. If this is a complex type, requires `options` to be defined.
 
### Files

- [ ] `path`: This is the path the file will be generated at. It can include `Stencil` tags to make it dynamic. This defaults to `template` if present
- [ ] `contents`: A file template string
- [ ] `template`: A path to a file template
- [ ] `context`: An optional context property path that will be passed to the template. If this resolves to an array, a file for each element will be created, using tags in `path` to differentiate them.

Each file can have a `contents` or `template`. If neither of those are present, the file will be copied exactly as is without any content replacement.
The final path of the file will be based off `path` otherwise `template`.

### Stencil Templates
Each Stencil template will have access to all the options. If the template is with an array it will get access to only that item within the array