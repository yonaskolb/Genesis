import Foundation
import PathKit

public class Writer {

    public init() {

    }
    
    public func createWriteResult(files: [GeneratedFile], path: Path, clean: Clean) throws -> WriteResult {
        let cleanFiles: [Path]
        switch clean {
        case .all:
            cleanFiles = try path.recursiveChildren().filter { $0.isFile }
        case .leaveDotFiles:
            let nonDotChildren = try path.children()
                .filter { !$0.lastComponentWithoutExtension.hasPrefix(".") }
                .filter { $0.isFile }
            let grandchildren = try nonDotChildren.reduce([]) { $0 + (try $1.recursiveChildren().filter { $0.isFile }) }
            cleanFiles = nonDotChildren + grandchildren
        case .none:
            cleanFiles = []
        }

        let generatedPaths = files.map { path + $0.path }
        let removedPaths = Array(Set(cleanFiles).subtracting(Set(generatedPaths))).sorted()

        let removedFiles: [FileResult] = removedPaths.map { FileResult(path: $0, state: .removed) }
        let generatedFiles = try files.map { try $0.getResult(basePath: path) }
        return WriteResult(files: removedFiles + generatedFiles)
    }

    public func writeResult(_ result: WriteResult) throws {
        for file in result.files {
            switch file.state {
            case .removed:
                try? file.path.delete()
            case let .modified(_, contents),
                 let .created(contents),
                 let .unchanged(contents):
                try file.path.parent().mkpath()
                try file.path.write(contents)
            }
        }
    }

    @discardableResult
    /// Convenience that calls createWriteResult() and then writeResult()
    public func writeFiles(_ files: [GeneratedFile], to path: Path, clean: Clean) throws -> WriteResult {
        let result = try createWriteResult(files: files, path: path, clean: clean)
        try writeResult(result)
        return result
    }
}

extension GeneratedFile {

    func getResult(basePath: Path) throws -> FileResult {
        let path = basePath + self.path
        let state: FileResult.State
        if path.exists {
            let existing: String = try path.read()
            if contents == existing {
                state = .unchanged(contents)
            } else {
                state = .modified(old: existing, new: contents)
            }
        } else {
            state = .created(contents)
        }
        return FileResult(path: path, state: state)
    }
}

public enum Clean: String {
    case none
    case leaveDotFiles
    case all
}

public struct FileResult {
    public let path: Path
    public let state: State

    public enum State {
        case created(String)
        case modified(old: String, new: String)
        case unchanged(String)
        case removed

        public enum StateType: String, CaseIterable {
            case created
            case modified
            case unchanged
            case removed
        }

        public var type: StateType {
            switch self {
            case .created: return .created
            case .modified: return .modified
            case .unchanged: return .unchanged
            case .removed: return .removed
            }
        }
    }
}

public struct WriteResult {

    public let files: [FileResult]
    public let created: [FileResult]
    public let modified: [FileResult]
    public let unchanged: [FileResult]
    public let removed: [FileResult]

    init(files: [FileResult]) {
        self.files = files
        func getFiles(_ state: FileResult.State.StateType) -> [FileResult] {
            return files.filter { $0.state.type == state }
        }
        created = getFiles(.created)
        modified = getFiles(.modified)
        unchanged = getFiles(.unchanged)
        removed = getFiles(.removed)
    }

    public var hasChanged: Bool {
        return files.contains { $0.state.type != .unchanged }
    }

    public func getFiles(_ state: FileResult.State.StateType) -> [FileResult] {
        switch state {
        case .created: return created
        case .modified: return modified
        case .unchanged: return unchanged
        case .removed: return removed
        }
    }

    public var description: String {
        let counts: [(type: FileResult.State.StateType, count: Int)] = [
            (.created, created.count),
            (.modified, modified.count),
            (.unchanged, unchanged.count),
            (.removed, removed.count),
        ]
        return counts
            .filter { $0.count > 0 }
            .map { "\($0.count) \($0.type.rawValue)" }
            .joined(separator: ", ")
    }

    public func changedDescription(includeModifiedContent: Bool) -> String {
        var changes: [String] = []
        if !created.isEmpty {
            let string = "Created:\n  " + created.map { $0.path.description }.joined(separator: "\n  ")
            changes.append(string)
        }
        if !modified.isEmpty {
            let string = "Modified:\n  " + modified.map { file in
                var string = file.path.description
                if includeModifiedContent,
                    case let .modified(old, new) = file.state,
                    let diff = String.getFirstDifferentLine(old, new) {
                    string += "\n  Diff at line \(diff.line):\n  \"\(diff.string1)\"\n  \"\(diff.string2)\"\n"
                }
                return string
            }.joined(separator: "\n  ")
            changes.append(string)
        }
        if !removed.isEmpty {
            let string = "Removed:\n  " + removed.map { $0.path.description }.joined(separator: "\n  ")
            changes.append(string)
        }
        return changes.joined(separator: "\n\n")
    }
}
