import Combine
import UIKit

final class DocumentCell: UICollectionViewCell {
    static let reuseIdentifier = Config.reuseIdentifier
    private var document: DocumentItem?
    private var cancellables = Set<AnyCancellable>()

    private let rectangleView: UIView = {
        let view = UIView()
        view.backgroundColor = Config.rectangleColor
        view.layer.cornerRadius = Config.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Config.titleFont
        label.textColor = Config.textColor
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) { nil }

    private func setupCell() {
        [rectangleView, titleLabel].forEach(contentView.addSubview)

        NSLayoutConstraint.activate([
            rectangleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            rectangleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rectangleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rectangleView.heightAnchor.constraint(equalToConstant: Config.rectangleHeight),

            titleLabel.topAnchor.constraint(equalTo: rectangleView.bottomAnchor, constant: Config.titleTopPadding),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])
    }

    func configure(with item: DocumentItem) {
        titleLabel.text = item.fileName
        document = item
        guard let publisher = document?.$conversionStates else { return }
        publisher
            .map { states in
                states.compactMap { format, state -> (ConversionFormat, Double)? in
                    if case .converting(let progress) = state {
                        return (format, progress)
                    }
                    return nil
                }.first?.1 ?? 0
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self, progress > 0 else { return }
                let updatedText = String(format: Self.Config.conversionTextFormat, item.fileName, progress * 100)
                self.titleLabel.text = updatedText
            }
            .store(in: &cancellables)
    }
}

extension DocumentCell {
    fileprivate struct Config {
        static let reuseIdentifier = "DocumentCell"
        static let rectangleColor: UIColor = .systemBlue
        static let cornerRadius: CGFloat = 8
        static let titleFont: UIFont = .systemFont(ofSize: 16, weight: .medium)
        static let textColor: UIColor = .black
        static let rectangleHeight: CGFloat = 100
        static let titleTopPadding: CGFloat = 10
        static let conversionTextFormat = "%@ %.0f%%"
    }
}
