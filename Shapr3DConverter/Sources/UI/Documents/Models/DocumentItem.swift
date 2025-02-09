import Combine
import Foundation

enum ConversionFormat: String, CaseIterable, Hashable {
    case step = ".step"
    case stl = ".stl"
    case obj = ".obj"
}

enum ConversionState {
    case idle
    case converting(progress: Double)
    case completed(URL)
    case failed(String)
}

final class DocumentItem: ObservableObject, Hashable {
    let id: UUID
    let fileURL: URL
    let fileName: String
    @Published var conversionStates: [ConversionFormat: ConversionState]

    private lazy var fileAttributes: [FileAttributeKey: Any]? = try? FileManager.default
        .attributesOfItem(atPath: fileURL.path)

    var fileSize: String {
        guard let fileSize = fileAttributes?[.size] as? Int64 else { return "Unknown" }
        return ByteCountFormatter().string(fromByteCount: fileSize)
    }

    var creationDate: Date? {
        fileAttributes?[.creationDate] as? Date
    }

    var modificationDate: Date? {
        fileAttributes?[.modificationDate] as? Date
    }

    var lastOpenedDate: Date? {
        let resourceValues = try? fileURL.resourceValues(forKeys: [.contentAccessDateKey])
        return resourceValues?.contentAccessDate
    }

    init(id: UUID = UUID(),
         fileURL: URL,
         fileName: String,
         conversionStates: [ConversionFormat: ConversionState]? = nil) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileName
        self.conversionStates = conversionStates ??
            Dictionary(uniqueKeysWithValues: ConversionFormat.allCases.map { ($0, .idle) })
    }

    static func == (lhs: DocumentItem, rhs: DocumentItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension DocumentItem {
    func toCacheable() -> DocumentItemCached {
        let states = Dictionary(uniqueKeysWithValues: conversionStates
            .map { ($0.key.rawValue, ConversionStateCodable(from: $0.value)) })

        return DocumentItemCached(
            id: id,
            fileName: fileName,
            fileURL: fileURL.lastPathComponent,
            conversionStates: states
        )
    }
}
