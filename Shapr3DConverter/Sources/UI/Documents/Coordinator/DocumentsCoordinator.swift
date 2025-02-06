import Combine
import Foundation
import UIKit

class DocumentsCoordinator: Coordinator<Void> {
    private let router: Router?
    private let viewController: DocumentGridViewController
    private var cancellables = Set<AnyCancellable>()
    private let itemsSubject = CurrentValueSubject<[DocumentItem], Never>([])
    private let converterManager = DocumentConversionManager(fileConverter: DocumentConversionEngine())
    private var fileSelectionCompletion: ((URL) -> Void)?

    init(router: Router) {
        self.router = router
        viewController = DocumentGridViewController(converterManager: converterManager)
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
                self?.viewController.updateItems(items)
            }
            .store(in: &cancellables)
    }

    fileprivate func selectFileAndConvert() {
        selectFile { [weak self] sourceURL in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                var newItems = self.itemsSubject.value
                let item = DocumentItem(id: UUID(),
                                        fileURL: sourceURL,
                                        fileName: sourceURL.lastPathComponent,
                                        fileSize: 0,
                                        conversionStates: [.obj: .idle,
                                                           .step: .idle,
                                                           .stl: .idle])
                newItems.append(item)
                self.itemsSubject.send(newItems)
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

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(selectedURL.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: selectedURL, to: destinationURL)
            fileSelectionCompletion?(destinationURL)
        } catch {
            print("Error copying file to Documents directory: \(error.localizedDescription)")
        }
    }
}

extension DocumentsCoordinator: DocumentGridViewControllerDelegate {
    func didTapAddItem() {
        selectFileAndConvert()
    }
}

// MARK: - Unit testing

#if DEBUG
extension DocumentsCoordinator {
    var testHooks: TestHooks {
        return TestHooks(target: self)
    }

    struct TestHooks {
        private let target: DocumentsCoordinator

        init(target: DocumentsCoordinator) {
            self.target = target
        }

        var itemsSubject: CurrentValueSubject<[DocumentItem], Never> {
            return target.itemsSubject
        }

        func selectFileAndConvertMock(_ testURL: URL) {
            target.selectFile { sourceURL in
                var newItems = target.itemsSubject.value
                let item = DocumentItem(id: UUID(),
                                        fileURL: sourceURL,
                                        fileName: sourceURL.lastPathComponent,
                                        fileSize: 0,
                                        conversionStates: [.obj: .idle])
                newItems.append(item)
                target.itemsSubject.send(newItems)
            }
            target.fileSelectionCompletion?(testURL)
        }

        func mockDocumentSelection(_ testURL: URL) {
            target.fileSelectionCompletion?(testURL)
        }
    }
}
#endif
