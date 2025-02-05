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
    let fileSize: Int
    @Published var conversionStates: [ConversionFormat: ConversionState]

    init(id: UUID = UUID(),
         fileURL: URL,
         fileName: String,
         fileSize: Int,
         conversionStates: [ConversionFormat: ConversionState]? = nil) {
        self.id = id
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
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
