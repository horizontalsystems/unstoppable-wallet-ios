

import UIKit

class AlertItemCell: BaseThemeCell {
    private let button = UIButton()

    var onSelect: (() -> Void)?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview().priority(.high)
        }

        button.titleLabel?.font = .body
        button.setTitleColor(.themeJacob, for: .selected)
        button.setTitleColor(.themeJacob, for: [.highlighted, .selected])
        button.setTitleColor(.themeLeah, for: .normal)
        button.setTitleColor(.themeGray50, for: .disabled)
        button.setBackgroundColor(color: .themeLawrence.pressed, forState: .highlighted)
        button.setBackgroundColor(color: .themeLawrence.pressed, forState: [.highlighted, .selected])
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onSelect?()
    }

    var isEnabled: Bool {
        get { button.isEnabled }
        set { button.isEnabled = newValue }
    }

    var title: String? {
        get { button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }

    override var isSelected: Bool {
        get { super.isSelected }
        set {
            super.isSelected = newValue
            button.isSelected = newValue
        }
    }
}
