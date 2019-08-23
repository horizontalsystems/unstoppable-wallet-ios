import UIKit
import SnapKit

class BalanceHeaderView: UIView {

    let amountLabel = UILabel()
    let statsSwitchButton = UIButton()

    var onStatsSwitch: ((Bool) -> ())?
    private var switchIsOn: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        backgroundColor = AppTheme.navigationBarBackgroundColor

        preservesSuperviewLayoutMargins = true

        addSubview(statsSwitchButton)
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: BalanceTheme.headerTintColorNormal), for: .normal)
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: BalanceTheme.headerTintColor), for: .selected)
        statsSwitchButton.setImage(UIImage(named: "Stats Switch Button")?.tinted(with: BalanceTheme.headerTintColorSelected), for: .highlighted)
        statsSwitchButton.snp.makeConstraints { maker in
            maker.trailingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.centerY.equalToSuperview()
        }
        statsSwitchButton.addTarget(self, action: #selector(onSwitch), for: .touchUpInside)

        addSubview(amountLabel)
        amountLabel.font = BalanceTheme.amountFont
        amountLabel.preservesSuperviewLayoutMargins = true

        amountLabel.snp.makeConstraints { maker in
            maker.leadingMargin.equalToSuperview().inset(self.layoutMargins)
            maker.top.equalToSuperview().offset(BalanceTheme.cellSmallMargin)
        }

        setSwitch(isOn: switchIsOn)
    }

    func bind(amount: String?, upToDate: Bool) {
        amountLabel.text = amount
        amountLabel.textColor = upToDate ? BalanceTheme.amountColor : BalanceTheme.amountColorSyncing
    }

    @objc func onSwitch() {
        switchIsOn = !switchIsOn
        setSwitch(isOn: switchIsOn)
        onStatsSwitch?(switchIsOn)
    }

    private func setSwitch(isOn: Bool) {
        statsSwitchButton.isSelected = isOn
    }

}
