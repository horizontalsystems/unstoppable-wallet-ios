import UIKit

@IBDesignable
class Button: UIButton {

    @IBInspectable
    var cornerRadius: CGFloat {
        get{
            return layer.cornerRadius
        }
        set{
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue != 0
        }
    }

}
