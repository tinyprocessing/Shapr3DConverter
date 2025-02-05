import Foundation
import UIKit

class ApplicationCoordinator: Coordinator<Void> {
    private let router: Router
    private let documentsCoordinator: DocumentsCoordinator

    init?(router: Router) {
        self.router = router
        documentsCoordinator = DocumentsCoordinator(router: router)
        super.init()
    }

    override func start() {
        super.start()
        launch()
    }

    private func launch() {
        let controller = documentsCoordinator.exportViewController()
        documentsCoordinator.start()
        router.willRouteWith(controller)
    }
}
