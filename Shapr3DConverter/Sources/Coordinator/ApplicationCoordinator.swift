import Foundation
import UIKit

class ApplicationCoordinator: Coordinator<Void> {
    private let router: Router
    private let documentsCoordinator: DocumentsCoordinator

    init?(router: Router) {
        self.router = router
        documentsCoordinator = DocumentsCoordinator(
            router: router,
            conversionManager: DocumentConversionManager(fileConverter: DocumentConversionEngine()),
            cachingService: DocumentCacheManager(),
            fileStorageService: DocumentFileManager(),
            documentPickerPresenter: DocumentPickerManager()
        )
        super.init()
    }

    override func start() {
        super.start()
        launch()
    }

    private func launch() {
        let controller = documentsCoordinator.exportViewController()
        addChild(coordinator: documentsCoordinator)
        documentsCoordinator.start()
        router.willRouteWith(controller)
    }

    func handleIncomingFiles(_ urls: [URL]) {
        documentsCoordinator.importFiles(urls: urls)
    }
}
