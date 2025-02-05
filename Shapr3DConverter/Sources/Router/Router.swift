import UIKit

class Router {
    let baseRoute: RouteType = .core
    let navigationController = UINavigationController()

    init(baseRoute: RouteType) {
        navigationController.navigationBar.isHidden = true
        navigationController.navigationBar.tintColor = Colors.PrimaryColor
        navigationController.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: Colors.BackgroundColor
        ]
    }

    private func viewControllerFor(route routeType: RouteType) -> BaseViewController {
        var controller: BaseViewController!
        switch routeType {
        case .core:
            controller = BaseViewController()
        }
        controller.delegate = self
        return controller
    }
}

extension Router: BaseViewControllerDelegate {
    func willRouteTo(_ routeType: RouteType) {
        let vc = viewControllerFor(route: routeType)
        navigationController.pushViewController(vc, animated: true)
    }

    func willRouteWithCover(_ vc: UIViewController) {
        vc.modalPresentationStyle = .overFullScreen
        navigationController.present(vc, animated: false)
    }

    func willRouteWith(_ vc: UIViewController) {
        navigationController.pushViewController(vc, animated: true)
    }

    func willRouteTab(_ vc: UITabBarController) {
        navigationController.pushViewController(vc, animated: true)
    }
}
