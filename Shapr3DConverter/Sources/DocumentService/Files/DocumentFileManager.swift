import Foundation

protocol DocumentFileManaging: AnyObject {
    func copyFile(from sourceURL: URL, to destinationURL: URL) -> (String, URL?)
    func removeFile(at url: URL) -> Bool
}

class DocumentFileManager: DocumentFileManaging {
    func copyFile(from sourceURL: URL, to destinationURL: URL) -> (String, URL?) {
        let uniquePrefix = UUID().uuidString
        let uniqueFileName = "\(uniquePrefix)_\(destinationURL.lastPathComponent)"
        let uniqueDestinationURL = destinationURL.deletingLastPathComponent().appendingPathComponent(uniqueFileName)

        do {
            if FileManager.default.fileExists(atPath: uniqueDestinationURL.path) {
                try FileManager.default.removeItem(at: uniqueDestinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: uniqueDestinationURL)
            return (sourceURL.lastPathComponent, uniqueDestinationURL)
        } catch {
            return ("", nil)
        }
    }

    func removeFile(at url: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            return true
        } catch {
            return false
        }
    }
}
