import Combine
import UIKit

final class DocumentCell: UICollectionViewCell {
    static let reuseIdentifier = Config.reuseIdentifier
    private var document: DocumentItem?
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

            let progressView = CircularProgressView(size: .init(width: 15, height: 15))
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
        titleLabel.text = item.fileName
        document = item

        if let imageData = try? Data(contentsOf: item.fileURL),
           let image = UIImage(data: imageData) {
            imageView.image = image
        }

        guard let publisher = document?.$conversionStates else { return }

        publisher.receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                guard let self = self else { return }

                self.conversionViews.forEach { format, view in
                    let label = view.subviews.compactMap { $0 as? UILabel }.first
                    if case .failed = states[format] {
                        label?.textColor = .init(hex: "e74c3c")
                    }
                    if case .idle = states[format] {
                        label?.textColor = .gray.withAlphaComponent(0.4)
                    }
                    if case .completed = states[format] {
                        label?.textColor = .init(hex: "2ecc71")
                    }
                    if case .converting(let progress) = states[format] {
                        label?.isHidden = true

                        let progressView = view.subviews.compactMap { $0 as? CircularProgressView }.first
                        progressView?.isHidden = false
                        progressView?.progress = progress
                    } else {
                        label?.isHidden = false

                        let progressView = view.subviews.compactMap { $0 as? CircularProgressView }.first
                        progressView?.isHidden = true
                    }
                }
            }
            .store(in: &cancellables)
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

extension DocumentCell {
    fileprivate struct Config {
        static let reuseIdentifier = "DocumentCell"
        static let cornerRadius: CGFloat = 8
        static let titleFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
        static let textColor: UIColor = .black
        static let imageHeight: CGFloat = 100
        static let titleTopPadding: CGFloat = 10
        static let conversionTextFormat = "%@ %.0f%%"
    }
}
