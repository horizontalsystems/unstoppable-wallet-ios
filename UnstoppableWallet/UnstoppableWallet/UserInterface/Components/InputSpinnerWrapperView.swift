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

    func size(containerWidth: CGFloat) -> CGSize {
        CGSize(width: 20, height: 20)
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

}
