import UIKit

extension UIControl {
    func addAction(for event: UIControl.Event = .touchUpInside, action: @escaping () -> Void) {
        addAction(UIAction { _ in action() }, for: event)
    }
}
