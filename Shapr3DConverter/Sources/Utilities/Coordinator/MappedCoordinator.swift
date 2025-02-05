import Foundation

open class MappedCoordinator<T, U>: Coordinator<U> {
    public let underlyingCoordinator: Coordinator<T>

    private let transform: (T) -> U

    public init(_ coordinator: Coordinator<T>, transform: @escaping (T) -> U) {
        underlyingCoordinator = coordinator
        self.transform = transform
    }

    open override func start() {
        super.start()

        addChild(coordinator: underlyingCoordinator)
        underlyingCoordinator.onFinish = { [weak self, transform] result in
            self?.finish(transform(result))
        }

        underlyingCoordinator.start()
    }
}

extension Coordinator {
    @inlinable public func map<U>(_ transform: @escaping (CoordinationResult) -> U) -> Coordinator<U> {
        let coordinator = MappedCoordinator(self, transform: transform)
        return coordinator
    }
}
