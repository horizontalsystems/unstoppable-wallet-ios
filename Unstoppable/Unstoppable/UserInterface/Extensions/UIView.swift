import UIKit

extension UIView {
    @IBInspectable
    open var cornerCurve: CALayerCornerCurve {
        get {
            layer.cornerCurve
        }
        set {
            layer.cornerCurve = newValue
        }
    }
}
