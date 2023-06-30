
public struct Option: Equatable, Decodable {

    public var name: String
    public var required: Bool
    public var value: String?
    public var description: String?
    public var question: String?
    public var type: OptionType
    public var branch: [String: TemplateSection]
    public var set: String
    public var choices: [String]
    public var childType: OptionType?
    public var options: [Option]?

    public enum OptionType: String, Decodable {
        case string
        case boolean
        case choice
        case array
    }

    public init(name: String, description: String? = nil, value: String? = nil, type: OptionType = .string, set: String? = nil, question: String? = nil, required: Bool = false, choices: [String] = [], branch: [String: TemplateSection] = [:], options: [Option]? = nil) {
        self.name = name
        self.value = value
        self.description = description
        self.type = type
        self.set = set ?? name
        self.required = required
        self.choices = choices
        self.question = question
        self.branch = branch
        self.options = options
    }

    enum CodingKeys: CodingKey {
        case name
        case value
        case required
        case question
        case type
        case branch
        case description
        case set
        case choices
        case childType
        case options
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decode(String.self, forKey: .name)
        self.name = name
        set = try container.decodeIfPresent(String.self, forKey: .set) ?? name
        description = try container.decodeIfPresent(String.self, forKey: .description)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        type = try container.decodeIfPresent(OptionType.self, forKey: .type) ?? .string
        childType = try container.decodeIfPresent(OptionType.self, forKey: .childType)
        choices = try container.decodeIfPresent([String].self, forKey: .choices) ?? []
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? false
        question = try container.decodeIfPresent(String.self, forKey: .question)
        branch = try container.decodeIfPresent([String: TemplateSection].self, forKey: .branch) ?? [:]
        options = try container.decodeIfPresent([Option].self, forKey: .options)
    }
}
