import UIKit

class TintImageView: UIImageView, RespondViewDelegate {

    private var _tintColor: UIColor?
    private var selectedTintColor: UIColor?

    init(image: UIImage?, tintColor: UIColor, selectedTintColor: UIColor) {
        super.init(image: image?.withRenderingMode(.alwaysTemplate))
        self.tintColor = tintColor
        self.selectedTintColor = selectedTintColor
    }

    init(image: UIImage?, selectedImage: UIImage?) {
        super.init(image: image)
        self.highlightedImage = selectedImage
    }

    override private init(image: UIImage?) {
        super.init(image: image)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func touchBegan() {
        if highlightedImage != nil {
            isHighlighted = true
        } else {
            _tintColor = tintColor
            tintColor = selectedTintColor
        }
    }

    func touchEnd() {
        isHighlighted = false
        tintColor = _tintColor
    }

}
