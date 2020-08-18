import UIKit
import HUD

class SwapHeaderView: UIView {
    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2

    private let titleLabel = UILabel()
    private let badgeView = BadgeView()

    private let processSpinner = HUDProgressView(
            strokeLineWidth: SwapHeaderView.spinnerLineWidth,
            radius: SwapHeaderView.spinnerRadius,
            strokeColor: .themeOz
    )

    public init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(badgeView)
        addSubview(processSpinner)

        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
        }

        titleLabel.font = .body
        titleLabel.textColor = .themeOz

        badgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel)
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin2x)
        }

        processSpinner.snp.makeConstraints { maker in
            maker.centerY.equalTo(titleLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.width.height.equalTo(SwapHeaderView.spinnerRadius * 2 + SwapHeaderView.spinnerLineWidth)
        }
        processSpinner.isHidden = true
    }

    func set(title: String?) {
        titleLabel.text = title
    }

    func setBadge(text: String?) {
        badgeView.set(text: text)
    }

    func setBadge(hidden: Bool) {
        badgeView.isHidden = hidden
    }

    func set(loading: Bool) {
        processSpinner.isHidden = !loading
        if loading {
            processSpinner.startAnimating()
        } else {
            processSpinner.stopAnimating()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}
