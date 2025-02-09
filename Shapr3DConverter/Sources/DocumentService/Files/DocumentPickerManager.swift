import Foundation
import UIKit
import UniformTypeIdentifiers

protocol DocumentPickerManaging: AnyObject {
    func presentDocumentPicker(
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool,
        on presenter: UIViewController,
        completion: @escaping ([URL]) -> Void
    )
}

class DocumentPickerManager: NSObject, DocumentPickerManaging, UIDocumentPickerDelegate {
    private var completion: (([URL]) -> Void)?

    func presentDocumentPicker(
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool,
        on presenter: UIViewController,
        completion: @escaping ([URL]) -> Void
    ) {
        self.completion = completion
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        documentPicker.allowsMultipleSelection = allowsMultipleSelection
        documentPicker.delegate = self
        presenter.present(documentPicker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion?(urls)
    }
}
