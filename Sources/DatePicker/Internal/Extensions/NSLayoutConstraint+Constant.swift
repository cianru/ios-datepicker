import UIKit

extension NSLayoutConstraint {
    func constant(_ value: CGFloat) -> NSLayoutConstraint {
        constant = value
        return self
    }
}
