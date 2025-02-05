import Combine
import Foundation

extension Publisher {
    /// Convenience function to easily await the next output from a publisher.
    ///
    /// - IMPORTANT: Since we're immediately returning upon receiving
    /// the first output value, that'll cancel our subscription to the current publisher.
    ///
    /// - NOTE: Uses Combine's `Publisher.values` property if iOS version
    /// is 15.0 or greater. Otherwise falls back to custom `CombineAsyncStreamBridge`.
    ///
    /// - Returns: The next output from the publisher.
    public func singleOutput() async throws -> Output {
        for try await output in values {
            return output
        }

        throw Publishers.MissingOutputError()
    }
}

extension Publishers {
    public struct MissingOutputError: Error {}
}
