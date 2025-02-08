import Combine
import UIKit

final class DocumentDetailView: UIView {
    private let format: ConversionFormat
    private var convertedFileURL: URL?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private lazy var convertButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = .localized(.convert)
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .medium
        config.buttonSize = .medium
        return UIButton(configuration: config)
    }()

    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = .localized(.cancel)
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .medium
        config.buttonSize = .medium
        return UIButton(configuration: config)
    }()

    private lazy var circularProgressView: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var successIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: Config.successImage)
        imageView.tintColor = .systemGreen
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    let convertActionPublisher = PassthroughSubject<Void, Never>()
    let cancelActionPublisher = PassthroughSubject<Void, Never>()
    let shareActionPublisher = PassthroughSubject<URL, Never>()

    init(format: ConversionFormat) {
        self.format = format
        super.init(frame: .zero)
        titleLabel.text = .localized(.convert_to, [.format: format.rawValue])
        setupLayout()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        let progressStack = UIStackView(arrangedSubviews: [titleLabel, circularProgressView, successIndicator])
        progressStack.axis = .horizontal
        progressStack.spacing = 12
        progressStack.alignment = .center
        progressStack.translatesAutoresizingMaskIntoConstraints = false

        let buttonsStack = UIStackView(arrangedSubviews: [convertButton, cancelButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12
        buttonsStack.distribution = .fillEqually
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = UIStackView(arrangedSubviews: [progressStack, errorLabel, buttonsStack])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: Config.stackSpacing),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Config.stackSpacing),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Config.stackSpacing),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Config.stackSpacing),

            circularProgressView.heightAnchor.constraint(equalToConstant: 30),
            circularProgressView.widthAnchor.constraint(equalToConstant: 30),

            successIndicator.heightAnchor.constraint(equalToConstant: 30),
            successIndicator.widthAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupActions() {
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }

    @objc private func convertTapped() {
        errorLabel.isHidden = true
        convertActionPublisher.send(())
        update(state: .converting(progress: 0))
    }

    @objc private func cancelTapped() {
        errorLabel.isHidden = true
        cancelActionPublisher.send(())
        update(state: .idle)
    }

    func update(state: ConversionState) {
        circularProgressView.isHidden = true
        successIndicator.isHidden = true
        errorLabel.isHidden = true
        cancelButton.isHidden = true

        switch state {
        case .idle:
            configureConvertButton()
        case .converting(let progress):
            circularProgressView.isHidden = false
            circularProgressView.progress = CGFloat(progress)
            cancelButton.isHidden = false
        case .completed(let url):
            convertedFileURL = url
            successIndicator.isHidden = false
            configureShareButton()
        case .failed(let message):
            errorLabel.text = message
            errorLabel.isHidden = false
            configureConvertButton()
        }
    }

    private func configureConvertButton() {
        var config = UIButton.Configuration.filled()
        config.title = .localized(.convert)
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .medium
        config.buttonSize = .medium
        convertButton.configuration = config
        convertButton.removeTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)
    }

    private func configureShareButton() {
        var config = UIButton.Configuration.filled()
        config.title = .localized(.share)
        config.baseBackgroundColor = .systemGreen
        config.cornerStyle = .medium
        config.buttonSize = .medium
        convertButton.configuration = config
        convertButton.removeTarget(self, action: #selector(convertTapped), for: .touchUpInside)
        convertButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }

    @objc private func shareTapped() {
        guard let url = convertedFileURL else { return }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsDirectory.appendingPathComponent(url.lastPathComponent)
        shareActionPublisher.send(filePath)
    }
}

extension DocumentDetailView {
    fileprivate enum Config {
        static let successImage = "checkmark.circle.fill"
        static let padding: CGFloat = 16
        static let stackSpacing: CGFloat = 16
    }
}
