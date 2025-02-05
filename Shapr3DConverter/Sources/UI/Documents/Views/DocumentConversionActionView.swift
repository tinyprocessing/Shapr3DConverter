import Combine
import UIKit

final class ConversionActionView: UIView {
    private let format: ConversionFormat
    private let button: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Convert", for: .normal)
        return b
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progress = 0
        return pv
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    let actionPublisher = PassthroughSubject<Void, Never>()

    init(format: ConversionFormat) {
        self.format = format
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = "Convert to \(format.rawValue)"
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        let stack = UIStackView(arrangedSubviews: [titleLabel, button, progressView, statusLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func buttonTapped() {
        actionPublisher.send(())
    }

    func update(state: ConversionState) {
        switch state {
        case .idle:
            progressView.progress = 0
            statusLabel.text = "Idle"
        case .converting(let progress):
            progressView.progress = Float(progress)
            statusLabel.text = "Converting: \(Int(progress * 100))%"
        case .completed:
            progressView.progress = 1.0
            statusLabel.text = "Completed"
        case .failed(let message):
            progressView.progress = 0
            statusLabel.text = "Failed: \(message)"
        }
    }
}
