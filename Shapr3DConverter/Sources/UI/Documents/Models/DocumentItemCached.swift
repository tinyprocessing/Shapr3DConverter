import Foundation

struct ConversionStateCodable: Codable {
    let type: String
    let progress: Double?
    let message: String?
    let fileURL: URL?

    init(from state: ConversionState) {
        switch state {
        case .idle:
            type = "idle"
            progress = nil
            message = nil
            fileURL = nil
        case .converting(let progress):
            type = "converting"
            self.progress = progress
            message = nil
            fileURL = nil
        case .completed(let fileURL):
            type = "completed"
            progress = nil
            message = nil
            self.fileURL = fileURL
        case .failed(let message):
            type = "failed"
            progress = nil
            self.message = message
            fileURL = nil
        }
    }

    func toConversionState() -> ConversionState? {
        switch type {
        case "idle": return .idle
        case "converting": return progress.map { .converting(progress: $0) }
        case "completed": return fileURL.map { .completed($0) }
        case "failed": return message.map { .failed($0) }
        default: return nil
        }
    }
}

struct DocumentItemCached: Codable {
    let id: UUID
    let fileName: String
    let conversionStates: [String: ConversionStateCodable]

    func toDocumentItem() -> DocumentItem? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        let states = conversionStates
            .compactMapKeys { ConversionFormat(rawValue: $0) }
            .compactMapValues { $0.toConversionState() }

        return DocumentItem(id: id, fileURL: fileURL, fileName: fileName, conversionStates: states)
    }
}

extension Dictionary {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}
