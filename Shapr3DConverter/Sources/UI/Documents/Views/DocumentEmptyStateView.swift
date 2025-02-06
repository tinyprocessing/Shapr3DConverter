import UIKit

final class EmptyStateView: UIStackView {
    init(title: String, description: String, iconName: String = "doc.text.magnifyingglass") {
        super.init(frame: .zero)
        setupView(title: title, description: description, iconName: iconName)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(title: String, description: String, iconName: String) {
        axis = .vertical
        spacing = 10
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false

        let image = UIImage(
            systemName: iconName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        )?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 2

        addArrangedSubview(imageView)
        addArrangedSubview(titleLabel)
        addArrangedSubview(descriptionLabel)
    }
}
