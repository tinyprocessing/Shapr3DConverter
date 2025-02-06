import Combine
import Foundation
import UIKit
import UniformTypeIdentifiers

class DocumentsCoordinator: Coordinator<Void> {
    private let router: Router?
    private let viewController: DocumentGridViewController
    private var cancellables = Set<AnyCancellable>()
    private let itemsSubject = CurrentValueSubject<[DocumentItem], Never>([])
    private let converterManager = DocumentConversionManager(fileConverter: DocumentConversionEngine())
    private var fileSelectionCompletion: (([URL]) -> Void)?

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
        selectFiles { [weak self] sourceURLs in
            guard let self = self else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                var newItems = self.itemsSubject.value
                for sourceURL in sourceURLs {
                    let item = DocumentItem(id: UUID(),
                                            fileURL: sourceURL,
                                            fileName: sourceURL.lastPathComponent,
                                            fileSize: 0,
                                            conversionStates: [.obj: .idle,
                                                               .step: .idle,
                                                               .stl: .idle])
                    newItems.append(item)
                }
                self.itemsSubject.send(newItems)
            }
        }
    }

    private func selectFiles(completion: @escaping ([URL]) -> Void) {
        fileSelectionCompletion = completion
        let shaprType = UTType(filenameExtension: "shapr") ?? .data
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [shaprType], asCopy: true)
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: true, completion: nil)
    }
}

extension DocumentsCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let shaprFiles = urls.filter { $0.pathExtension.lowercased() == "shapr" }
        guard !shaprFiles.isEmpty else { return }

        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        var copiedURLs: [URL] = []
        for selectedURL in shaprFiles {
            let destinationURL = documentsDirectory.appendingPathComponent(selectedURL.lastPathComponent)

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.copyItem(at: selectedURL, to: destinationURL)
                copiedURLs.append(destinationURL)
            } catch {
                print("Error copying file \(selectedURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        fileSelectionCompletion?(copiedURLs)
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

        func selectFileAndConvertMock(_ testURL: URL) {}

        func mockDocumentSelection(_ testURL: URL) {
            target.fileSelectionCompletion?([testURL])
        }
    }
}
#endif
