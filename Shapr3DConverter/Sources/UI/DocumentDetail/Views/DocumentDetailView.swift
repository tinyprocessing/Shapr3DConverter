import Combine
import UIKit

final class DocumentDetailView: UIView {
    private let format: ConversionFormat
    private var convertedFileURL: URL?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let convertButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = .localized(.convert)
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .medium
        config.buttonSize = .medium
        return UIButton(configuration: config)
    }()

    private let cancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = .localized(.cancel)
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .medium
        config.buttonSize = .medium
        return UIButton(configuration: config)
    }()

    private let circularProgressView: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let successIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemGreen
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private let errorLabel: UILabel = {
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
        titleLabel.text = "Convert to \(format.rawValue)"
        setupLayout()
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
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
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            circularProgressView.heightAnchor.constraint(equalToConstant: 30),
            circularProgressView.widthAnchor.constraint(equalToConstant: 30),

            successIndicator.heightAnchor.constraint(equalToConstant: 30),
            successIndicator.widthAnchor.constraint(equalToConstant: 30)
        ])
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

    @objc private func shareTapped() {
        guard let url = convertedFileURL else { return }
        shareActionPublisher.send(url)
    }

    func update(state: ConversionState) {
        switch state {
        case .idle:
            circularProgressView.isHidden = true
            successIndicator.isHidden = true
            errorLabel.isHidden = true
            cancelButton.isHidden = true
            configureConvertButton()

        case .converting(let progress):
            circularProgressView.isHidden = false
            circularProgressView.progress = CGFloat(progress)
            successIndicator.isHidden = true
            errorLabel.isHidden = true
            cancelButton.isHidden = false

        case .completed(let url):
            convertedFileURL = url
            circularProgressView.isHidden = true
            successIndicator.isHidden = false
            errorLabel.isHidden = true
            cancelButton.isHidden = true
            configureShareButton()

        case .failed(let message):
            circularProgressView.progress = 0
            circularProgressView.isHidden = true
            successIndicator.isHidden = true
            errorLabel.text = message
            errorLabel.isHidden = false
            cancelButton.isHidden = true
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
}
