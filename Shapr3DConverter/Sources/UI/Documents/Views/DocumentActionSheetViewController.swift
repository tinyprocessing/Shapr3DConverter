import Combine
import UIKit

final class DocumentActionSheetViewController: UIViewController {
    private let document: DocumentItem
    private let fileConverter: FileConverter
    private var cancellables = Set<AnyCancellable>()

    private lazy var stackView: UIStackView = {
        let views = ConversionFormat.allCases.map { format -> ConversionActionView in
            let view = ConversionActionView(format: format)
            view.actionPublisher
                .sink { [weak self] in self?.startConversion(for: format) }
                .store(in: &self.cancellables)
            self.document.$conversionStates
                .map { $0[format] ?? .idle }
                .receive(on: DispatchQueue.main)
                .sink { state in view.update(state: state) }
                .store(in: &self.cancellables)
            return view
        }
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(document: DocumentItem, fileConverter: FileConverter) {
        self.document = document
        self.fileConverter = fileConverter
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func startConversion(for format: ConversionFormat) {
        guard case .idle = document.conversionStates[format] ?? .idle else { return }
        document.conversionStates[format] = .converting(progress: 0)
        let targetURL = document.fileURL.deletingLastPathComponent()
            .appendingPathComponent("converted_" + document.fileURL.lastPathComponent)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                try fileConverter.convert(from: document.fileURL,
                                          to: targetURL) { [weak self] progress in
                    self?.document.conversionStates[format] = .converting(progress: progress)
                    return .continue
                }
            } catch {
                document.conversionStates[format] = .failed(error.localizedDescription)
            }
        }
    }
}
