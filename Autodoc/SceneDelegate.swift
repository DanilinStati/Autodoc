import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = makeWindow(for: windowScene)
        let coordinator = AppCoordinator(window: window, dependencies: .live)
        coordinator.start()

        self.window = window
        self.coordinator = coordinator
    }

    private func makeWindow(for windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.tintColor = .brand
        return window
    }
}
