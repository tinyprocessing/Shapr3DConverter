import Combine
import Foundation
import UIKit

public protocol CoordinatorChildDelegate: AnyObject {
    func coordinatorDidAdd<T, U>(_ coordinator: Coordinator<T>, child: Coordinator<U>)
    func coordinatorDidRemove<T, U>(_ coordinator: Coordinator<T>, child: Coordinator<U>)
}

open class Coordinator<CoordinationResult>: UIResponder {
    public weak var childDelegate: CoordinatorChildDelegate?

    public var result: CoordinationResult {
        get async {
            try! await resultSubject.compactMap { $0 }.singleOutput()
        }
    }

    public var onFinish: ((CoordinationResult) -> Void)?

    let identifier = UUID()
    var cleanupFromParentBlock: (() -> Void)?

    private let resultSubject = CurrentValueSubject<CoordinationResult?, Never>(nil)
    private var children = [UUID: Any]()

    open func start() {}

    public final func startAndWaitForResult() async -> CoordinationResult {
        start()
        return await result
    }

    open func finish(_ result: CoordinationResult) {
        onFinish?(result)
        resultSubject.value = result
        cleanupFromParentBlock?()
    }

    public func addChild<T>(coordinator: Coordinator<T>) {
        coordinator.cleanupFromParentBlock = { [weak self, weak coordinator] in
            self?.removeChild(coordinator: coordinator)
        }
        children[coordinator.identifier] = coordinator
        childDelegate?.coordinatorDidAdd(self, child: coordinator)
    }

    private func removeChild<T>(coordinator: Coordinator<T>?) {
        guard let coordinator = coordinator else {
            return
        }

        children.removeValue(forKey: coordinator.identifier)
        childDelegate?.coordinatorDidRemove(self, child: coordinator)
    }
}

open class CoordinatorResponder<CoordinationResult, CoordinatableType: Coordinatable>: Coordinator<CoordinationResult> {
    open var childResponder: CoordinatableType? {
        nil
    }

    open override var next: UIResponder? {
        childResponder?.originalNextResponder
    }

    public override init() {
        super.init()
        childResponder?.coordinator = self as? Coordinator<CoordinatableType.CoordinationResult>
    }
}
