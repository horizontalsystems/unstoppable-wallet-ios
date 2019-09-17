import UIKit
import SnapKit

class SwitchCellView: UIView {
    private let switchView = UISwitch()
    private var onSwitch: ((Bool) -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        switchView.tintColor = .appSteel20
        switchView.setContentCompressionResistancePriority(.required, for: .horizontal)
        switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        addSubview(switchView)
        switchView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-AppTheme.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func switchChanged() {
        onSwitch?(switchView.isOn)
    }

    func bind(isOn: Bool, onSwitch: @escaping (Bool) -> ()) {
        switchView.isOn = isOn
        self.onSwitch = onSwitch
    }

}
