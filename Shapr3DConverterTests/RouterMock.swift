import UIKit
@testable import Shapr3DConverter

final class RouterMock: Router {
    var lastPushedViewController: UIViewController?
    var lastPresentedViewController: UIViewController?
}
