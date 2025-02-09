import Combine
import UIKit

final class DocumentGridCell: UICollectionViewCell {
    static let reuseIdentifier = Config.reuseIdentifier
    private weak var document: DocumentItem?
    private var cancellables = Set<AnyCancellable>()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Config.cornerRadius
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Config.titleFont
        label.textColor = Config.textColor
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var conversionViews: [ConversionFormat: UIView] = {
        var views: [ConversionFormat: UIView] = [:]
        ConversionFormat.allCases.forEach { format in
            let view = UIView()
            view.backgroundColor = .white
            view.layer.cornerRadius = 8
            view.layer.masksToBounds = true
            view.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = format.rawValue.uppercased()
            label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false

            let progressView = CircularProgressView(size: Config.progressBarSize)
            progressView.isHidden = true
            progressView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(label)
            view.addSubview(progressView)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
                label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),

                progressView.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
                progressView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
                progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
                progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6)
            ])
            views[format] = view
        }
        return views
    }()

    private lazy var conversionStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: conversionViews.values.map { $0 })
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        document = nil
        imageView.image = nil
    }

    required init?(coder: NSCoder) { nil }

    private func setupCell() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.addSubview(conversionStack)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: Config.imageHeight),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: Config.titleTopPadding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

            conversionStack.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            conversionStack.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with item: DocumentItem) {
        cancellables.removeAll()
        titleLabel.text = item.fileName
        document = item

        loadImage(from: item.fileURL)

        guard let publisher = document?.$conversionStates else { return }

        publisher.receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                self?.updateConversionViews(with: states)
            }
            .store(in: &cancellables)
    }

    private func loadImage(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard let imageData = try? Data(contentsOf: url),
                  let image = UIImage(data: imageData)
            else { return }

            DispatchQueue.main.async {
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

    private func updateConversionViews(with states: [ConversionFormat: ConversionState]) {
        conversionViews.forEach { format, view in
            guard let label = view.subviews.compactMap({ $0 as? UILabel }).first else { return }
            let progressView = view.subviews.compactMap { $0 as? CircularProgressView }.first

            switch states[format] {
            case .failed: label.textColor = Config.failureColor
            case .idle: label.textColor = Config.idleColor
            case .completed: label.textColor = Config.completedColor
            case .converting(let progress):
                label.isHidden = true
                progressView?.isHidden = false
                progressView?.progress = progress
                return
            default: break
            }

            label.isHidden = false
            progressView?.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        adjustConversionStackForSmallScreens()
    }

    private func adjustConversionStackForSmallScreens() {
        let availableWidth = bounds.width

        if availableWidth < 200 {
            conversionStack.axis = .vertical
            conversionStack.spacing = 4

            conversionViews.values.forEach { view in
                let label = view.subviews.compactMap { $0 as? UILabel }.first
                label?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
                view.layer.cornerRadius = 6
            }
        } else {
            conversionStack.axis = .horizontal
            conversionStack.spacing = 8

            conversionViews.values.forEach { view in
                let label = view.subviews.compactMap { $0 as? UILabel }.first
                label?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                view.layer.cornerRadius = 8
            }
        }
    }
}

extension DocumentGridCell {
    fileprivate enum Config {
        static let reuseIdentifier = "DocumentCell"
        static let cornerRadius: CGFloat = 8
        static let titleFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
        static let textColor: UIColor = .black
        static let imageHeight: CGFloat = 100
        static let titleTopPadding: CGFloat = 10
        static let failureColor: UIColor = .init(hex: "e74c3c")
        static let completedColor: UIColor = .init(hex: "2ecc71")
        static let idleColor: UIColor = .systemGray.withAlphaComponent(0.7)
        static let progressBarSize: CGSize = .init(width: 15, height: 15)
    }
}
