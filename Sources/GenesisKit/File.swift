
public struct File: Equatable, Decodable {

    public var type: FileType
    public var path: String
    public var include: String?
    public var context: String?

    public enum FileType: Equatable {
        case template(String)
        case contents(String)
        case copy(String)
        case directory
    }

    enum CodingKeys: CodingKey {
        case contents
        case template
        case path
        case include
        case context
        case copy
    }

    public init(type: FileType, path: String, include: String? = nil, context: String? = nil) {
        self.type = type
        self.path = path
        self.include = include
        self.context = context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        include = try container.decodeIfPresent(String.self, forKey: .include)
        context = try container.decodeIfPresent(String.self, forKey: .context)
        if let contents = try container.decodeIfPresent(String.self, forKey: .contents) {
            type = .contents(contents)
            path = try container.decode(String.self, forKey: .path)
        } else if let template = try container.decodeIfPresent(String.self, forKey: .template) {
            type = .template(template)
            path = try container.decode(String.self, forKey: .path)
        } else if let copy = try container.decodeIfPresent(String.self, forKey: .copy) {
            type = .copy(copy)
            if let path = try container.decodeIfPresent(String.self, forKey: .path) {
                self.path = path
            } else {
                self.path = copy
            }
        } else {
            type = .directory
            path = try container.decode(String.self, forKey: .path)
        }
    }
}
