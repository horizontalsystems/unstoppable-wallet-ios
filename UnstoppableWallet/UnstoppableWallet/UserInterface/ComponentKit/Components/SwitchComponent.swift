import SnapKit
import UIKit

public class SwitchComponent: UIView {
    public let switchView = UISwitch()

    public var onSwitch: ((Bool) -> Void)?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(switchView)
        switchView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        switchView.setContentCompressionResistancePriority(.required, for: .horizontal)
        switchView.setContentHuggingPriority(.required, for: .horizontal)
        switchView.tintColor = .themeSteel20
        switchView.onTintColor = .themeYellowD
        switchView.addTarget(self, action: #selector(onToggle), for: .valueChanged)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onToggle() {
        onSwitch?(switchView.isOn)
    }
}
