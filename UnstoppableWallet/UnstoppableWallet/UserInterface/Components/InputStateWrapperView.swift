import UIKit
import ThemeKit
import SnapKit
import HUD

class InputStateWrapperView: UIView, ISizeAwareView {
    private let spinner = HUDActivityView.create(with: .small20)
    private let successImageView = UIImageView()

    init() {
        super.init(frame: .zero)

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        addSubview(successImageView)
        successImageView.snp.makeConstraints { maker in
            maker.edges.equalTo(spinner)
        }

        successImageView.image = UIImage(named: "circle_check_20")?.withRenderingMode(.alwaysTemplate)
        successImageView.tintColor = .themeRemus
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

    var isSuccessVisible: Bool = false {
        didSet {
            successImageView.alpha = isSuccessVisible ? 1 : 0
        }
    }

    func width(containerWidth: CGFloat) -> CGFloat {
        20
    }

}
