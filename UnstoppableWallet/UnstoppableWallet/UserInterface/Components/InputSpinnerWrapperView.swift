import UIKit
import ThemeKit
import SnapKit
import HUD

class InputSpinnerWrapperView: UIView, ISizeAwareView {
    private let spinner = HUDActivityView.create(with: .small20)

    init() {
        super.init(frame: .zero)

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHidden: Bool {
        get {
            super.isHidden
        }
        set {
            super.isHidden = newValue

            if isHidden {
                spinner.stopAnimating()
            } else {
                spinner.startAnimating()
            }
        }
    }

    var isSpinnerVisible: Bool = false {
        didSet {
            if isSpinnerVisible {
                spinner.alpha = 1
                spinner.stopAnimating()
            } else {
                spinner.alpha = 0
                spinner.startAnimating()
            }
        }
    }

    func width(containerWidth: CGFloat) -> CGFloat {
        20
    }

}
