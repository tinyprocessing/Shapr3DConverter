import UIKit

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    NSStringFromClass(CoreApplication.self),
    NSStringFromClass(AppDelegate.self)
)

private final class CoreApplication: UIApplication {
    override func sendEvent(_ event: UIEvent) {
        eventOccurred(event)
        super.sendEvent(event)
    }

    private func eventOccurred(_ event: UIEvent) {}
}
