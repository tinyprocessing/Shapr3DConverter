import Foundation

open class AnyCoordinator<T>: Coordinator<Any> {
    public let underlyingCoordinator: Coordinator<T>

    public init(_ coordinator: Coordinator<T>) {
        underlyingCoordinator = coordinator
    }

    open override func start() {
        super.start()

        addChild(coordinator: underlyingCoordinator)
        underlyingCoordinator.onFinish = { [weak self] result in
            self?.finish(result)
        }

        underlyingCoordinator.start()
    }
}

extension Coordinator {
    public func eraseToAnyCoordinator() -> Coordinator<Any> {
        AnyCoordinator(self)
    }
}
