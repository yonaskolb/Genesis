import Yams
import PathKit

public struct Template {
    public var section: TemplateSection
    public var path: Path

    public init(path: Path, section: TemplateSection) {
        self.path = path
        self.section = section
    }

    public init(path: Path) throws {
        let string: String = try path.read()
        try self.init(path: path, string: string)
    }

    public init(path: Path, string: String) throws {
        let decoder = YAMLDecoder()
        let section: TemplateSection = try decoder.decode(from: string)
        self.init(path: path, section: section)
    }
}

public struct TemplateSection: Decodable {
    public var options: [Option]
    public var files: [File]

    public init(files: [File] = [], options: [Option] = []) {
        self.files = files
        self.options = options
    }

    enum CodingKeys: CodingKey {
        case options
        case files
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        options = try container.decodeIfPresent([Option].self, forKey: .options) ?? []
        files = try container.decodeIfPresent([File].self, forKey: .files) ?? []
    }
}
