import Combine
import Foundation

/// Class conforming to AsyncSequence and AsyncIteratorProtocol, used to bridge combine to Async/Await.
public class CombineAsyncStreamBridge<Upstream: Publisher>: AsyncSequence, AsyncIteratorProtocol {
    public typealias Element = Upstream.Output
    public typealias AsyncIterator = CombineAsyncStreamBridge<Upstream>

    private let stream: AsyncThrowingStream<Upstream.Output, Error>

    private var cancellable: AnyCancellable?
    private lazy var iterator = stream.makeAsyncIterator()

    /// Creates an instance of `CombineAsyncStreamBridge` from an upstream publisher.
    ///
    /// - Parameter upstream: The upstream publisher to bridge to AsyncSequence
    public init(_ upstream: Upstream) {
        var subscription: AnyCancellable?

        stream = AsyncThrowingStream<Upstream.Output, Error> { continuation in
            subscription = upstream
                .handleEvents(
                    receiveCancel: {
                        continuation.finish(throwing: nil)
                    }
                )
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .failure(let error):
                            continuation.finish(throwing: error)
                        case .finished: continuation.finish(throwing: nil)
                        }
                    },
                    receiveValue: { value in
                        continuation.yield(value)
                    }
                )
        }

        cancellable = subscription
    }

    /// Cancels the `CombineAsyncStreamBridge`'s subscription to the upstream publisher.
    public func cancel() {
        cancellable?.cancel()
        cancellable = nil
    }

    /// `AsyncSequence` protocol conformance.
    public func makeAsyncIterator() -> Self {
        return self
    }

    /// `AsyncIteratorProtocol` protocol conformance.
    public func next() async throws -> Upstream.Output? {
        return try await iterator.next()
    }
}

extension Publisher {
    /// Convenience method for creating a asyncStream from an upstream `Publisher`.
    ///
    /// - Returns: An `CombineAsyncStreamBridge` based on the `Publisher`
    public func asyncStream() -> CombineAsyncStreamBridge<Self> {
        return CombineAsyncStreamBridge(self)
    }
}
