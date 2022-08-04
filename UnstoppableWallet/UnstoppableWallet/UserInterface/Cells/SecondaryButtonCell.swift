import UIKit
import ThemeKit
import ComponentKit

class SecondaryButtonCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin16
    static let height: CGFloat = SecondaryButton.height + 2 * verticalPadding

    private let button = SecondaryButton()

    var onTap: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

    var title: String? {
        get { button.title(for: .normal) }
        set { button.setTitle(newValue, for: .normal) }
    }

    var isEnabled: Bool {
        get { button.isEnabled }
        set { button.isEnabled = newValue }
    }

    func set(style: SecondaryButton.Style) {
        button.set(style: style)
    }

}
