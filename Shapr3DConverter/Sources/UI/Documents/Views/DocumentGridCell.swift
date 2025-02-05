import UIKit

final class DocumentCell: UICollectionViewCell {
    static let reuseIdentifier = Config.reuseIdentifier

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
        titleLabel.text = item.title
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
    }
}
