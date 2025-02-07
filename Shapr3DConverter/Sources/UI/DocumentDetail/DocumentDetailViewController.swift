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
        let views = ConversionFormat.allCases.sorted(by: { $0.rawValue < $1.rawValue })
            .map { format -> DocumentDetailView in
                let view = DocumentDetailView(format: format)
                view.shareActionPublisher
                    .sink { [weak self] url in
                        guard let self = self else { return }
                        let activityViewController = UIActivityViewController(
                            activityItems: [url],
                            applicationActivities: nil
                        )

                        if let popoverController = activityViewController.popoverPresentationController {
                            popoverController.sourceView = self.view
                            popoverController.sourceRect = CGRect(
                                x: self.view.bounds.midX,
                                y: self.view.bounds.midY,
                                width: 0,
                                height: 0
                            )
                            popoverController.permittedArrowDirections = []
                        }

                        self.present(activityViewController, animated: true)
                    }
                    .store(in: &self.cancellables)
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
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(imageView)
        contentView.addSubview(stackView)

        setupConstraints()
        loadImage(from: document.fileURL)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func loadImage(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let imageData = try? Data(contentsOf: url),
                  let image = UIImage(data: imageData)
            else { return }

            DispatchQueue.main.async {
                // This will fix memory, without resize image will take 70+ mb
                let resizedImage = self.resizeImage(image, to: self.imageView.bounds.size)
                self.imageView.image = resizedImage
            }
        }
    }

    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
