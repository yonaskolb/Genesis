import Foundation

public typealias Context = [String: Any]

extension String {

    static func getFirstDifferentLine(_ string1: String, _ string2: String) -> (string1: String, string2: String, line: Int)? {
        guard string1 != string2 else { return nil }

        let commonPrefix = string1.commonPrefix(with: string2)
        let startOfLine = commonPrefix.range(of: "\n", options: .backwards, range: commonPrefix.startIndex ..< commonPrefix.endIndex, locale: nil)

        let startIndex = startOfLine?.upperBound ?? commonPrefix.startIndex

        let endOfLine1 = string1.range(of: "\n", options: [], range: commonPrefix.endIndex ..< string1.endIndex, locale: nil)?.lowerBound ?? string1.endIndex
        let endOfLine2 = string2.range(of: "\n", options: [], range: commonPrefix.endIndex ..< string2.endIndex, locale: nil)?.lowerBound ?? string2.endIndex

        let diff1 = String(string1[startIndex ..< endOfLine1])
        let diff2 = String(string2[startIndex ..< endOfLine2])

        let line = commonPrefix.components(separatedBy: "\n").count + 1
        return (diff1, diff2, line)
    }
}
