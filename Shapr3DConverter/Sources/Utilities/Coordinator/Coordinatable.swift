import Foundation
import UIKit

public protocol Coordinatable: AnyObject {
    associatedtype CoordinationResult

    var coordinator: Coordinator<CoordinationResult>? { get set }
    var originalNextResponder: UIResponder? { get }
}
