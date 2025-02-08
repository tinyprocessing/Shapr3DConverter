@testable import Shapr3DConverter
import UIKit

final class RouterMock: Router {
    var lastPushedViewController: UIViewController?
    var lastPresentedViewController: UIViewController?
}
