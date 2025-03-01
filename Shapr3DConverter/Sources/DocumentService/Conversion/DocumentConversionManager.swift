import Combine
import Foundation

protocol DocumentConversionManaging: AnyObject {
    func cancelAllConversions(for document: DocumentItem)
    func startConversion(for document: DocumentItem, format: ConversionFormat)
    func cancelConversion(for document: DocumentItem, format: ConversionFormat)
}

final class DocumentConversionManager: DocumentConversionManaging {
    private let fileConverter: FileConverterProtocol
    private var conversionSubscriptions: [ConversionKey: AnyCancellable] = [:]

    private struct ConversionKey: Hashable {
        let documentID: UUID
        let format: ConversionFormat
    }

    init(fileConverter: FileConverterProtocol) {
        self.fileConverter = fileConverter
    }

    func startConversion(for document: DocumentItem, format: ConversionFormat) {
        let key = ConversionKey(documentID: document.id, format: format)
        conversionSubscriptions[key]?.cancel()

        document.conversionStates[format] = .converting(progress: 0)
        let targetURL = fileConverter.outputURL(for: document.fileURL, format: format, fileName: document.fileName)

        let publisher = fileConverter.convertPublisher(from: document.fileURL, to: targetURL)
            .receive(on: DispatchQueue.main)

        let subscription = publisher.sink { [weak self] completion in
            guard let self else { return }
            switch completion {
            case .failure(let error):
                if error is CancellationError {
                    document.conversionStates[format] = .idle
                } else {
                    document.conversionStates[format] = .failed(error.localizedDescription)
                }
            case .finished:
                let outputURL = fileConverter.outputURL(for: document.fileURL,
                                                        format: format,
                                                        fileName: document.fileName)
                document.conversionStates[format] = .completed(outputURL)
            }
            conversionSubscriptions.removeValue(forKey: key)
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

    func cancelAllConversions(for document: DocumentItem) {
        ConversionFormat.allCases.forEach { format in
            let key = ConversionKey(documentID: document.id, format: format)
            conversionSubscriptions[key]?.cancel()
            conversionSubscriptions.removeValue(forKey: key)
            document.conversionStates[format] = .idle
        }
    }
}
