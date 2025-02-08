import Combine
import UIKit

final class DocumentDetailViewController: UIViewController {
    private let document: DocumentItem
    private let conversionManager: DocumentConversionManager
    private var cancellables = Set<AnyCancellable>()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: createDetailViews())
        stack.axis = .vertical
        stack.spacing = Config.stackSpacing
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
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadImage(from: document.fileURL)
    }

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(stackView)
        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: Config.imageHeight),
            stackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: Config.stackTopPadding),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Config.stackSidePadding),
            stackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Config.stackSidePadding
            ),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Config.stackBottomPadding)
        ])
    }

    private func loadImage(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self, let imageData = try? Data(contentsOf: url),
                  let image = UIImage(data: imageData)
            else { return }
            DispatchQueue.main.async {
                UIView.transition(
                    with: self.imageView,
                    duration: Config.imageFadeDuration,
                    options: .transitionCrossDissolve
                ) {
                    self.imageView.image = image.resized(to: CGSize(width: self.view.bounds.width,
                                                                    height: Config.imageHeight))
                }
            }
        }
    }

    private func createDetailViews() -> [UIView] {
        ConversionFormat.allCases.sorted(by: { $0.rawValue < $1.rawValue }).map { format in
            let view = DocumentDetailView(format: format)
            view.shareActionPublisher
                .sink { [weak self] url in self?.presentShareSheet(for: url) }
                .store(in: &cancellables)
            view.convertActionPublisher
                .sink { [weak self] in self?.conversionManager.startConversion(for: self!.document, format: format) }
                .store(in: &cancellables)
            view.cancelActionPublisher
                .sink { [weak self] in self?.conversionManager.cancelConversion(for: self!.document, format: format) }
                .store(in: &cancellables)
            document.$conversionStates
                .map { $0[format] ?? .idle }
                .receive(on: DispatchQueue.main)
                .sink { view.update(state: $0) }
                .store(in: &cancellables)
            return view
        }
    }

    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        present(activityVC, animated: true)
    }
}

private enum Config {
    static let stackSpacing: CGFloat = 16
    static let stackTopPadding: CGFloat = 20
    static let stackSidePadding: CGFloat = 20
    static let stackBottomPadding: CGFloat = 20
    static let imageHeight: CGFloat = 200
    static let imageFadeDuration: TimeInterval = 0.3
    static let imagePreviewSize = CGSize(width: 300, height: 200)
}
