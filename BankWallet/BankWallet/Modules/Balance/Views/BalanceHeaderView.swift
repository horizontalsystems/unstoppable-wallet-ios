import UIKit
import SnapKit

class BalanceHeaderView: UIView {
    static let height: CGFloat = .heightSingleLineCell

    private let amountLabel = UILabel()
    private let statsSwitchButton = UIButton()

    var onStatsSwitch: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        preservesSuperviewLayoutMargins = true

        let wrapperView = UIView()
        wrapperView.backgroundColor = AppTheme.navigationBarBackgroundColor

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(BalanceHeaderView.height)
        }

        amountLabel.font = .appTitle3
        amountLabel.preservesSuperviewLayoutMargins = true

        wrapperView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        statsSwitchButton.isHidden = true
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: .appGray), for: .normal)
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: .appJacob), for: .selected)
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: .appYellow50), for: .highlighted)
        statsSwitchButton.addTarget(self, action: #selector(onSwitch), for: .touchUpInside)

        wrapperView.addSubview(statsSwitchButton)
        statsSwitchButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(60)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(amount: String?, upToDate: Bool, statsIsOn: Bool) {
        amountLabel.text = amount
        amountLabel.textColor = upToDate ? .appJacob : .appYellow50
    }

    @objc func onSwitch() {
        onStatsSwitch?()
    }

    func set(statsButtonState: StatsButtonState) {
        switch statsButtonState {
        case .normal:
            statsSwitchButton.isHidden = false
            statsSwitchButton.isSelected = false
        case .selected:
            statsSwitchButton.isHidden = false
            statsSwitchButton.isSelected = true
        case .hidden:
            statsSwitchButton.isHidden = true
        }
    }

}
