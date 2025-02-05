import UIKit

protocol BaseViewControllerDelegate: AnyObject {
    func willRouteTo(_ routeType: RouteType)
}

class BaseViewController: UIViewController {
    weak var delegate: BaseViewControllerDelegate?

    var opaqueOverlay: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray.withAlphaComponent(0.2)
        return view
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(opaqueOverlay)
        NSLayoutConstraint.activate([
            opaqueOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            opaqueOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            opaqueOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            opaqueOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        opaqueOverlay.isHidden = true
    }

    func route(to routeType: RouteType) {
        delegate?.willRouteTo(routeType)
    }

    func prepareToDisplay() {}
}
