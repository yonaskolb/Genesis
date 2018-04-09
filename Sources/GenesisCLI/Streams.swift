import Foundation
import SwiftCLI

public struct Streams {

    public static let `default` = Streams()

    public let out: WritableStream
    public let error: WritableStream
    public let `in`: ReadableStream

    public init(
        out: WritableStream = WriteStream.stdout,
        error: WritableStream = WriteStream.stderr,
        in: ReadableStream = ReadStream.stdin
    ) {
        self.out = out
        self.error = error
        self.in = `in`
    }
}
