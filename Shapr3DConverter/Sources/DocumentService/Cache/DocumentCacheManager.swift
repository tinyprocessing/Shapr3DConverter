import Combine
import Foundation

protocol DocumentCaching: AnyObject {
    func saveDocuments(_ documents: [DocumentItem])
    func restoreDocuments() -> [DocumentItem]
}

final class DocumentCacheManager: DocumentCaching {
    private let cacheFileName = ".documents_cache.json"

    // MARK: - Save Documents to Cache

    func saveDocuments(_ documents: [DocumentItem]) {
        DispatchQueue.global(qos: .background).async {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let cacheableItems = documents.map { $0.toCacheable() }
            do {
                let data = try encoder.encode(cacheableItems)
                let cacheURL = self.cacheFileURL()
                try data.write(to: cacheURL)
            } catch {
                return
            }
        }
    }

    // MARK: - Restore Documents from Cache

    func restoreDocuments() -> [DocumentItem] {
        let decoder = JSONDecoder()

        do {
            let cacheURL = cacheFileURL()
            guard FileManager.default.fileExists(atPath: cacheURL.path) else { return [] }
            let data = try Data(contentsOf: cacheURL)
            let cachedItems = try decoder.decode([DocumentItemCached].self, from: data)

            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

            return cachedItems.compactMap { cachedItem in
                let filePath = documentsDirectory.appendingPathComponent(cachedItem.fileName)
                return FileManager.default.fileExists(atPath: filePath.path) ? cachedItem.toDocumentItem() : nil
            }
        } catch {
            return []
        }
    }

    // MARK: - Cache File URL

    private func cacheFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(cacheFileName)
    }
}
