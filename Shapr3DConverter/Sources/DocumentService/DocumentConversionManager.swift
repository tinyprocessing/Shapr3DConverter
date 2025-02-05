import Combine
import Foundation

final class DocumentConversionManager {
    private let fileConverter: DocumentConversionEngine
    private var conversionSubscriptions: [ConversionKey: AnyCancellable] = [:]

    private struct ConversionKey: Hashable {
        let documentID: UUID
        let format: ConversionFormat
    }

    init(fileConverter: DocumentConversionEngine) {
        self.fileConverter = fileConverter
    }

    func startConversion(for document: DocumentItem, format: ConversionFormat) {
        let key = ConversionKey(documentID: document.id, format: format)
        conversionSubscriptions[key]?.cancel()

        document.conversionStates[format] = .converting(progress: 0)
        let targetURL = document.fileURL.deletingLastPathComponent()
            .appendingPathComponent("converted_" + document.fileURL.lastPathComponent)

        let publisher = fileConverter.convertPublisher(from: document.fileURL, to: targetURL)
            .receive(on: DispatchQueue.main)

        let subscription = publisher.sink { [weak self] completion in
            guard let self = self else { return }
            switch completion {
            case .failure(let error):
                if error is CancellationError {
                    document.conversionStates[format] = .idle
                } else {
                    document.conversionStates[format] = .failed(error.localizedDescription)
                }
            case .finished:
                let outputURL = self.fileConverter.outputURL(for: document.fileURL, format: format)
                document.conversionStates[format] = .completed(outputURL)
            }
            self.conversionSubscriptions.removeValue(forKey: key)
        } receiveValue: { progress in
            document.conversionStates[format] = .converting(progress: progress)
        }
        conversionSubscriptions[key] = subscription
    }

    func cancelConversion(for document: DocumentItem, format: ConversionFormat) {
        let key = ConversionKey(documentID: document.id, format: format)
        conversionSubscriptions[key]?.cancel()
        conversionSubscriptions.removeValue(forKey: key)
        document.conversionStates[format] = .idle
    }
}
