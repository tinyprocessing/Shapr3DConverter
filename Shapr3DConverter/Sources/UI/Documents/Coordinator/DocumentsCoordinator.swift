import Combine
import Foundation
import UIKit
import UniformTypeIdentifiers

final class DocumentsCoordinator: Coordinator<Void> {
    private let router: Router?
    private let viewController: DocumentGridViewController
    private var cancellables = Set<AnyCancellable>()
    private var documentSubscriptions = [UUID: AnyCancellable]()
    private let itemsSubject = CurrentValueSubject<[DocumentItem], Never>([])
    private let documentPickerManager: DocumentPickerManaging
    private let conversionManager: DocumentConversionManaging
    private let fileManager: DocumentFileManaging
    private let cachingService: DocumentCaching

    init(router: Router?,
         conversionManager: DocumentConversionManaging,
         cachingService: DocumentCaching,
         fileStorageService: DocumentFileManaging,
         documentPickerPresenter: DocumentPickerManaging) {
        self.router = router
        self.conversionManager = conversionManager
        self.cachingService = cachingService
        fileManager = fileStorageService
        documentPickerManager = documentPickerPresenter
        viewController = DocumentGridViewController(converterManager: conversionManager)
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
            .sink { [weak self] items in
                guard let self = self else { return }

                let currentIDs = Set(items.map { $0.id })
                let removedIDs = Set(self.documentSubscriptions.keys).subtracting(currentIDs)
                removedIDs.forEach { id in
                    self.documentSubscriptions[id]?.cancel()
                    self.documentSubscriptions.removeValue(forKey: id)
                }

                items.forEach { item in
                    guard self.documentSubscriptions[item.id] == nil else { return }

                    let subscription = item.$conversionStates
                        .map { (item.id, $0) }
                        .sink { [weak self] _, states in
                            guard let self = self else { return }
                            for (_, state) in states {
                                switch state {
                                case .completed, .failed:
                                    self.saveDocumentsToCache()
                                default:
                                    break
                                }
                            }
                        }
                    self.documentSubscriptions[item.id] = subscription
                }
            }
            .store(in: &cancellables)
    }

    private func selectFileAndConvert() {
        documentPickerManager.presentDocumentPicker(allowedContentTypes: [Config.shaprType],
                                                    allowsMultipleSelection: true,
                                                    on: viewController) { [weak self] sourceURLs in
            self?.processImportedFiles(sourceURLs)
        }
    }

    func importFiles(urls: [URL]) {
        processImportedFiles(urls)
    }

    private func processImportedFiles(_ urls: [URL]) {
        let shaprFiles = urls.filter { $0.pathExtension.lowercased() == Constants.fileExtension }
        guard !shaprFiles.isEmpty,
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let copiedURLs = shaprFiles.compactMap {
            fileManager.copyFile(from: $0, to: documentsDirectory.appendingPathComponent($0.lastPathComponent))
        }

        let newItems: [DocumentItem] = copiedURLs.compactMap { value in
            if let url = value.1 {
                return DocumentItem(
                    id: UUID(),
                    fileURL: url,
                    fileName: value.0,
                    conversionStates: Config.defaultConversionStates
                )
            }
            return nil
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.itemsSubject.send(self.itemsSubject.value + newItems)
            self.saveDocumentsToCache()
        }
    }

    private func saveDocumentsToCache() {
        cachingService.saveDocuments(itemsSubject.value)
    }

    private func restoreCachedDocuments() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            let restoredItems = self.cachingService.restoreDocuments()
            DispatchQueue.main.async {
                self.itemsSubject.send(restoredItems)
            }
        }
    }
}

extension DocumentsCoordinator: DocumentGridViewControllerDelegate {
    func didOpenFile(_ url: URL) {
        processImportedFiles([url])
    }

    func didTapDeleteItem(_ document: DocumentItem) {
        documentSubscriptions[document.id]?.cancel()
        documentSubscriptions.removeValue(forKey: document.id)

        conversionManager.cancelAllConversions(for: document)
        _ = fileManager.removeFile(at: document.fileURL)

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
    static let shaprType = UTType(filenameExtension: Constants.fileExtension) ?? .data
    static let defaultConversionStates: [ConversionFormat: ConversionState] = [
        .obj: .idle,
        .step: .idle,
        .stl: .idle
    ]
}
