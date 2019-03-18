
import Foundation
import GenesisKit
import PathKit
import SwiftCLI
import Yams

class GenerateCommand: Command {

    let name = "generate"
    let shortDescription = "Generates files based on a template"

    let templatePath = Parameter()

    let optionPath = Key<String>("-p", "--option-path", description: "Path to a yaml or json file containing options")

    let destinationPath = Key<String>("-d", "--destination", description: "Path to the directory where output will be generated. Defaults to the current directory")

    let optionsArgument = Key<String>("-o", "--options", description: "Provide option overrides, in the format --options \"option1: value 2, option2: value 2.")

    let nonInteractive = Flag("-n", "--non-interactive", description: "Do not prompt for required options")

    let stream: Streams

    init(stream: Streams) {
        self.stream = stream
    }

    func execute() throws {
        let templatePath = Path(self.templatePath.value).absolute()
        let destinationPath = self.destinationPath.value.flatMap { Path($0) }?.absolute() ?? Path()

        var context: Context = [:]

        // extract options from env
        context = ProcessInfo.processInfo.environment

        // extract options from option path
        if let optionPath = self.optionPath.value {
            let path = Path(optionPath)
            if !path.exists {
                stream.out <<< "Option path \(optionPath) doesn't exist"
                exit(1)
            }
            let string: String = try path.read()
            guard let dictionary = try Yams.load(yaml: string) as? [String: Any] else {
                stream.out <<< "Option path decoding failed"
                exit(1)
            }

            for (key, value) in dictionary {
                context[key] = value
            }
        }

        // extract options from options argument
        if let commandLineOptions = optionsArgument.value {
            let optionList: [String] = commandLineOptions
                .split(separator: ",")
                .map(String.init)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            let optionPairs: [(String, String)] = optionList
                .map { option in
                    option
                        .split(separator: ":")
                        .map(String.init)
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                }
                .filter { $0.count == 2 }
                .map { ($0[0], $0[1]) }

            for (key, value) in optionPairs {
                context[key] = value
            }
        }

        let template = try Template(path: templatePath)
        let contextResolver = ContextResolver(template: template, interactive: !nonInteractive.value)
        context = try contextResolver.resolveOptions(context: context)
        if let optionPath = self.optionPath.value {
            let optionFile = Path(optionPath)
            context = try contextResolver.resolveOptionFile(optionFile, context: context)
        }
        let fileGenerator = FileGenerator(template: template)
        let generatedFiles = try fileGenerator.generate(context: context)
        let writer = Writer()
        let writeResult = try writer.writeFiles(generatedFiles, to: destinationPath, clean: .none)

        stream.out <<< writeResult.changedDescription(includeModifiedContent: true)
    }
}
