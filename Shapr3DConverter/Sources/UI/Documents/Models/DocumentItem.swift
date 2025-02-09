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
