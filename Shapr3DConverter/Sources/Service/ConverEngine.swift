import Foundation

enum ProgressAction {
    case `continue`
    case abort
}

protocol FileConverterProtocol {
    func convert(from sourceURL: URL, to targetURL: URL, progress: ((_ progress: Double) -> ProgressAction)?) throws
}

final class FileConverter: FileConverterProtocol {
    private enum Config {
        static let bufferSize = 1024
        static let errorProbability: UInt = 10000
        static let minDelay: UInt32 = 1000
        static let maxDelay: UInt32 = 10000
    }

    func convert(from sourceURL: URL, to targetURL: URL, progress: ((_ progress: Double) -> ProgressAction)?) throws {
        let totalBytes = try FileManager.default
            .attributesOfItem(atPath: sourceURL.path)[.size] as? UInt64 ??
            { throw ConversionError.inputError(error: nil) }()
        let input = try FileHandle(forReadingFrom: sourceURL)
        guard FileManager.default.createFile(atPath: targetURL.path, contents: nil, attributes: nil)
        else { throw ConversionError.outputError(error: nil) }
        let output = try FileHandle(forWritingTo: targetURL)

        var bytesWritten = 0

        while true {
            guard UInt.random(in: 0...Config.errorProbability) != 0 else { throw ConversionError.dataError }
            usleep(UInt32.random(in: Config.minDelay...Config.maxDelay))

            guard let readData = try input.read(upToCount: Config.bufferSize), !readData.isEmpty else { return }
            let convertedData = Data(readData.map { ~$0 })
            try output.write(contentsOf: convertedData)

            bytesWritten += convertedData.count
            if progress?(Double(bytesWritten) / Double(totalBytes)) == .abort { throw ConversionError.aborted }
        }
    }

    enum ConversionError: Error {
        case aborted
        case inputError(error: Error? = nil)
        case outputError(error: Error? = nil)
        case dataError
    }
}
