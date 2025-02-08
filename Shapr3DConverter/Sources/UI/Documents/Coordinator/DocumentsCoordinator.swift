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
    private let cacheManager = DocumentCacheManager()

    init(router: Router) {
        self.router = router
        viewController = DocumentGridViewController(converterManager: converterManager)
        super.init()
        bindViewModel()
        viewController.documentDelegate = self
    }

    override func start() {
        super.start()
        restoreCachedDocuments()
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
        observeConversionStateChanges()
    }

    private func observeConversionStateChanges() {
        itemsSubject
            .flatMap { items in
                Publishers.MergeMany(
                    items.map { item in
                        item.$conversionStates
                            .map { (item.id, $0) }
                    }
                )
            }
            .sink { [weak self] _, states in
                guard let self else { return }

                for (_, state) in states {
                    switch state {
                    case .completed:
                        saveDocumentsToCache()
                    case .failed:
                        saveDocumentsToCache()
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func selectFileAndConvert() {
        selectFiles { [weak self] sourceURLs in
            self?.processImportedFiles(sourceURLs)
        }
    }

    func importFiles(urls: [URL]) {
        processImportedFiles(urls)
    }

    private func processImportedFiles(_ urls: [URL]) {
        let shaprFiles = urls.filter { $0.pathExtension.lowercased() == Config.fileExtension }
        guard !shaprFiles.isEmpty else { return }

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                          in: .userDomainMask).first!
        let copiedURLs = shaprFiles.compactMap { copyFile(
            from: $0,
            to: documentsDirectory.appendingPathComponent($0.lastPathComponent)
        ) }

        let newItems = copiedURLs.map {
            DocumentItem(
                id: UUID(),
                fileURL: $0,
                fileName: $0.lastPathComponent,
                conversionStates: Config.defaultConversionStates
            )
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            itemsSubject.send(itemsSubject.value + newItems)
            saveDocumentsToCache()
        }
    }

    private func selectFiles(completion: @escaping ([URL]) -> Void) {
        fileSelectionCompletion = completion
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [Config.shaprType],
            asCopy: true
        )
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = self
        viewController.present(documentPicker, animated: true)
    }

    // MARK: Cache actions

    private func saveDocumentsToCache() {
        let items = itemsSubject.value
        cacheManager.saveDocuments(items)
    }

    private func restoreCachedDocuments() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            let restoredItems = cacheManager.restoreDocuments()
            DispatchQueue.main.async {
                self.itemsSubject.send(restoredItems)
            }
        }
    }
}

extension DocumentsCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let shaprFiles = urls.filter { $0.pathExtension.lowercased() == Config.fileExtension }
        guard !shaprFiles.isEmpty else { return }
        fileSelectionCompletion?(shaprFiles)
    }

    private func copyFile(from sourceURL: URL, to destinationURL: URL) -> URL? {
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }
}

extension DocumentsCoordinator: DocumentGridViewControllerDelegate {
    func didOpenFile(_ url: URL) {
        processImportedFiles([url])
    }

    func didTapDeleteItem(_ document: DocumentItem) {
        converterManager.cancelAllConversions(for: document)

        // TODO: Remove middle / full state files under processing
        do {
            if FileManager.default.fileExists(atPath: document.fileURL.path) {
                try FileManager.default.removeItem(at: document.fileURL)
            }
        } catch {}

        var currentItems = itemsSubject.value
        currentItems.removeAll { $0.id == document.id }

        itemsSubject.send(currentItems)
        saveDocumentsToCache()
    }

    func didTapAddItem() {
        selectFileAndConvert()
    }
}

private enum Config {
    static let fileExtension = "shapr"
    static let shaprType = UTType(filenameExtension: fileExtension) ?? .data
    static let defaultConversionStates: [ConversionFormat: ConversionState] = [
        .obj: .idle, .step: .idle, .stl: .idle
    ]
}
