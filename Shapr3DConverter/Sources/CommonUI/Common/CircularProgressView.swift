import UIKit

final class CircularProgressView: UIView {
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let size: CGSize

    var progress: CGFloat = 0 {
        didSet {
            progressLayer.strokeEnd = progress
        }
    }

    init(size: CGSize = .init(width: 30, height: 30)) {
        self.size = size
        super.init(frame: .zero)
        setupLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        let lineWidth: CGFloat = 8
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.systemGray4.cgColor

        progressLayer.lineWidth = lineWidth
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.systemBlue.cgColor
        progressLayer.strokeEnd = 0

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let lineWidth = progressLayer.lineWidth
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(size.width, size.height) / 2 - lineWidth / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        let circularPath = UIBezierPath(arcCenter: centerPoint,
                                        radius: radius,
                                        startAngle: startAngle,
                                        endAngle: endAngle,
                                        clockwise: true)
        backgroundLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }
}
