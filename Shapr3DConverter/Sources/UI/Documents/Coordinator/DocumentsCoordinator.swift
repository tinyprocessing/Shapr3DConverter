import Combine
import Foundation
import UIKit

class DocumentsCoordinator: Coordinator<Void> {
    private let router: Router?
    private let viewController: DocumentGridViewController
    private var cancellables = Set<AnyCancellable>()
    private let itemsSubject = CurrentValueSubject<[DocumentItem], Never>([])

    init(router: Router) {
        self.router = router
        viewController = DocumentGridViewController()
        super.init()
        bindViewModel()
    }

    override func start() {
        super.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { @MainActor in
            self.addMoreItems()
        }
    }

    func exportViewController() -> BaseViewController {
        return viewController
    }

    private func bindViewModel() {
        itemsSubject
            .sink { [weak self] items in
                print(items)
                self?.viewController.updateItems(items)
            }
            .store(in: &cancellables)
    }

    func addMoreItems() {
        var newItems = itemsSubject.value
        newItems.append(contentsOf: (1...5).map { DocumentItem(id: UUID(), title: "New File \($0)") })
        itemsSubject.send(newItems)
    }
}
