import Combine
import Foundation
import UIKit

class DocumentsCoordinator: Coordinator<Void> {
    private let router: Router?
    private let viewController: DocumentGridViewController
    private var cancellables = Set<AnyCancellable>()
    private let itemsSubject = CurrentValueSubject<[DocumentItem], Never>([])
    private let converter = FileConverter()
    private var fileSelectionCompletion: ((URL) -> Void)?

    init(router: Router) {
        self.router = router
        viewController = DocumentGridViewController()
        super.init()
        bindViewModel()
        viewController.documentDelegate = self
    }

    override func start() {
        super.start()
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

    fileprivate func selectFileAndConvert() {
        selectFile { [weak self] sourceURL in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    var newItems = self.itemsSubject.value
                    let item = DocumentItem(id: UUID(),
                                            fileURL: sourceURL,
                                            fileName: sourceURL.lastPathComponent,
                                            fileSize: 0,
                                            conversionStates: [.obj: .idle, .step: .idle, .stl: .idle])
                    newItems.append(item)
                    self.itemsSubject.send(newItems)
                }
            }
        }
    }

    private func selectFile(completion: @escaping (URL) -> Void) {
        fileSelectionCompletion = completion
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: true, completion: nil)
    }
}

extension DocumentsCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        fileSelectionCompletion?(selectedURL)
    }
}

extension DocumentsCoordinator: DocumentGridViewControllerDelegate {
    func didSelect(document: DocumentItem) {
        let sheetVC = DocumentActionSheetViewController(document: document, fileConverter: converter)
        viewController.present(sheetVC, animated: true, completion: nil)
    }

    func didTapAddItem() {
        selectFileAndConvert()
    }
}
