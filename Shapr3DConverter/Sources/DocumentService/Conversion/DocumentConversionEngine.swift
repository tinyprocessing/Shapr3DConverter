import Combine
import Foundation

enum ProgressAction {
    case `continue`
    case abort
}

protocol FileConverterProtocol {
    func convertPublisher(from sourceURL: URL, to targetURL: URL) -> AnyPublisher<Double, Error>
}

final class DocumentConversionEngine: FileConverterProtocol {
    private enum Config {
        static let bufferSize = 1024
        static let errorProbability: UInt = 10000
        static let minDelay: UInt32 = 1000
        static let maxDelay: UInt32 = 10000
    }

    func convertPublisher(from sourceURL: URL, to targetURL: URL) -> AnyPublisher<Double, Error> {
        let subject = PassthroughSubject<Double, Error>()
        var workItem: DispatchWorkItem!
        workItem = DispatchWorkItem {
            do {
                let fileManager = FileManager.default
                let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
                guard let totalBytes = attributes[.size] as? UInt64 else {
                    throw ConversionError.inputError(error: nil)
                }
                let input = try FileHandle(forReadingFrom: sourceURL)
                guard fileManager.createFile(atPath: targetURL.path, contents: nil, attributes: nil) else {
                    throw ConversionError.outputError(error: nil)
                }
                let output = try FileHandle(forWritingTo: targetURL)
                defer {
                    input.closeFile()
                    output.closeFile()
                }
                var bytesWritten = 0
                while !workItem.isCancelled {
                    if UInt.random(in: 0...Config.errorProbability) == 0 {
                        throw ConversionError.dataError
                    }
                    usleep(UInt32.random(in: Config.minDelay...Config.maxDelay))
                    guard let readData = try input.read(upToCount: Config.bufferSize),
                          !readData.isEmpty
                    else {
                        subject.send(completion: .finished)
                        return
                    }
                    let convertedData = Data(readData.map { ~$0 })
                    try output.write(contentsOf: convertedData)
                    bytesWritten += convertedData.count
                    let progressValue = Double(bytesWritten) / Double(totalBytes)
                    subject.send(progressValue)
                }
                if workItem.isCancelled {
                    subject.send(completion: .failure(CancellationError()))
                }
            } catch {
                subject.send(completion: .failure(error))
            }
        }
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        return subject
            .handleEvents(receiveCancel: {
                workItem.cancel()
            })
            .eraseToAnyPublisher()
    }

    enum ConversionError: Error {
        case aborted
        case inputError(error: Error? = nil)
        case outputError(error: Error? = nil)
        case dataError
    }
}

extension DocumentConversionEngine {
    func outputURL(for inputURL: URL, format: ConversionFormat) -> URL {
        let fileExtension = format.rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return inputURL.deletingPathExtension().appendingPathExtension(fileExtension)
    }
}
