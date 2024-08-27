import UIKit

extension CGFloat {
    var screenScaleRounded: CGFloat {
        let result = floor(self)
        let fractionalPart = self - result
        let screenScale = UIScreen.main.scale
        return result + ceil(fractionalPart * screenScale) / screenScale
    }
}
