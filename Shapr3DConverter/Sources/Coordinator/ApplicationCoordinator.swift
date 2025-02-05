import Foundation
import UIKit

class ApplicationCoordinator: Coordinator<Void> {
    private let router: Router

    init?(router: Router) {
        self.router = router
        super.init()
    }

    override func start() {
        super.start()
        launch()
    }

    private func launch() {
        configureVCs()
        load()
    }

    private func configureVCs() {
        let viewController = UIViewController()
        viewController.view?.backgroundColor = .white
        router.willRouteWith(viewController)
    }

    private func load() {}
}
