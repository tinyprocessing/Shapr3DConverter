import Combine
import UIKit

final class DocumentDetailView: UIView {
    private let format: ConversionFormat

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        return label
    }()

    private let convertButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Convert"
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .medium
        config.buttonSize = .medium

        let button = UIButton(configuration: config)
        return button
    }()

    private let cancelButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Cancel"
        config.baseBackgroundColor = .systemRed
        config.cornerStyle = .medium
        config.buttonSize = .medium

        let button = UIButton(configuration: config)
        return button
    }()

    private let circularProgressView: CircularProgressView = {
        let view = CircularProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        let buttonsStack = UIStackView(arrangedSubviews: [convertButton, cancelButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 12
        buttonsStack.distribution = .fillEqually
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false

        let progressStack = UIStackView(arrangedSubviews: [titleLabel, circularProgressView])
        progressStack.axis = .horizontal
        progressStack.spacing = 12
        progressStack.alignment = .center
        progressStack.translatesAutoresizingMaskIntoConstraints = false

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
            circularProgressView.widthAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func convertTapped() {
        errorLabel.isHidden = true
        convertActionPublisher.send(())
    }

    @objc private func cancelTapped() {
        errorLabel.isHidden = true
        cancelActionPublisher.send(())
    }

    func update(state: ConversionState) {
        switch state {
        case .idle:
            circularProgressView.progress = 0
            circularProgressView.isHidden = true
            errorLabel.isHidden = true
        case .converting(let progress):
            circularProgressView.isHidden = false
            circularProgressView.progress = CGFloat(progress)
            errorLabel.isHidden = true
        case .completed:
            circularProgressView.progress = 1
            errorLabel.isHidden = true
        case .failed(let message):
            circularProgressView.progress = 0
            errorLabel.text = message
            errorLabel.isHidden = false
        }
    }
}
