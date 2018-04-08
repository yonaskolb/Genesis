
import SwiftCLI
import Generator
import PathKit
import GenesisTemplate
import Foundation
import Yams

class GenerateCommand: Command {
    
    let name = "generate"
    let shortDescription = "Generates files based on a template"

    let templatePath = Parameter()

    let optionPath = Key<String>("-p", "--option-path", description: "Path to a yaml or json file containing options")

    let destinationPath = Key<String>("-d", "--destination", description: "Path to the directory where output will be generated. Defaults to the current directory")

    let optionsArgument = Key<String>("-o", "--options", "Provide option overrides, in the format --options \"option1: value 2, option2: value 2.\nOptions are comma delimited, and key value is colon delimited. Any white space is trimmed")

    let nonInteractive = Flag("-n", "--non-interactive", description: "Do not prompt for required options")

    let stream: Streams

    init(stream: Streams) {
        self.stream = stream
    }

    func execute() throws {
        let templatePath = Path(self.templatePath.value).absolute()
        let destinationPath = self.destinationPath.value.flatMap { Path($0) }?.absolute() ?? Path()

        var options: [String: Any] = [:]

        // extract options from env
        options = ProcessInfo.processInfo.environment

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
                options[key] = value
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
                options[key] = value
            }
        }

        let template = try GenesisTemplate(path: templatePath)
        let generator = try TemplateGenerator(template: template, interactive: !nonInteractive.value)

        let result = try generator.generate(path: destinationPath, options: options)
        let filePaths = result.files.map { "  \($0.path.string)" }.joined(separator: "\n")
        for file in result.files {
            let path = destinationPath + file.path
            try path.parent().mkpath()
            try path.write(file.contents)
        }
        stream.out <<< "Generated files:\n\(filePaths)"
    }
}
