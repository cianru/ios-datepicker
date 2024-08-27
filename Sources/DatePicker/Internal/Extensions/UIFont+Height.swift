import UIKit

extension UIFont {
    func height(numberOfLines: Int = 1) -> CGFloat {
        return (lineHeight * CGFloat(numberOfLines)).screenScaleRounded
    }
}
