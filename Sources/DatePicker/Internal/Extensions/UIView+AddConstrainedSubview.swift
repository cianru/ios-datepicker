import UIKit

extension UIView {
    func addConstrainedSubview(_ subview: UIView, constraints: [NSLayoutConstraint]) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        NSLayoutConstraint.activate(constraints)
    }
}
