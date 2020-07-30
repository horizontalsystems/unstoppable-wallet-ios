import UIKit
import ThemeKit

class ButtonCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin4x

    private let button = ThemeButton()

    private var onTap: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview().inset(ButtonCell.verticalPadding)
            maker.height.equalTo(CGFloat.heightButton)
        }

        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

    func bind(style: ThemeButtonStyle, title: String?, onTap: (() -> ())?) {
        button.isEnabled = true
        button.apply(style: style)
        button.setTitle(title, for: .normal)
        self.onTap = onTap
    }

    func disable() {
        button.isEnabled = false
    }
}

extension ButtonCell {

    static func height() -> CGFloat {
        .heightButton + 2 * verticalPadding
    }

}
