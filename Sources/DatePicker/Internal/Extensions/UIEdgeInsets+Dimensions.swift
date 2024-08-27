import UIKit

extension UIEdgeInsets {
    var vertical: CGFloat { top + bottom }
    var horizontal: CGFloat { left + right }

    init(value: CGFloat) {
        self.init(top: value, left: value, bottom: value, right: value)
    }

    init(vertical: CGFloat = 0, horizontal: CGFloat = 0) {
        self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}
