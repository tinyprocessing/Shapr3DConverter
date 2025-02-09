import Foundation

protocol DocumentFileManaging: AnyObject {
    func copyFile(from sourceURL: URL, to destinationURL: URL) -> URL?
    func removeFile(at url: URL) -> Bool
}

class DocumentFileManager: DocumentFileManaging {
    func copyFile(from sourceURL: URL, to destinationURL: URL) -> URL? {
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            return nil
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
