import Combine
import UIKit

final class DocumentDetailViewController: UIViewController {
    private let document: DocumentItem
    private let conversionManager: DocumentConversionManager
    private var cancellables = Set<AnyCancellable>()

    private lazy var stackView: UIStackView = {
        let views = ConversionFormat.allCases.sorted(by: { $0.rawValue < $1.rawValue })
            .map { format -> DocumentDetailView in
                let view = DocumentDetailView(format: format)
                view.convertActionPublisher
                    .sink { [weak self] in
                        guard let self = self else { return }
                        self.conversionManager.startConversion(for: self.document, format: format)
                    }
                    .store(in: &self.cancellables)
                view.cancelActionPublisher
                    .sink { [weak self] in
                        guard let self = self else { return }
                        self.conversionManager.cancelConversion(for: self.document, format: format)
                    }
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

    init(document: DocumentItem, conversionManager: DocumentConversionManager) {
        self.document = document
        self.conversionManager = conversionManager
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
}
