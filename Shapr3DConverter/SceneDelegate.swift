import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let router = Router(baseRoute: Constants.initialRouteType)
    private var coordinator: ApplicationCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.rootViewController = router.navigationController
        window?.makeKeyAndVisible()
        window?.tintColor = Colors.PrimaryColor

        coordinator = ApplicationCoordinator(router: router)
        if let coordinator {
            coordinator.start()
            coordinator.onFinish = { _ in }
        }

        let fileURLs = connectionOptions.urlContexts.map { $0.url }
        if !fileURLs.isEmpty {
            coordinator?.handleIncomingFiles(fileURLs)
        }
    }

    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        let fileURLs = URLContexts.map { $0.url }
        if !fileURLs.isEmpty {
            coordinator?.handleIncomingFiles(fileURLs)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
