import UIKit
import ThemeKit

class BottomSheetRedButtonCell: UITableViewCell {
    static let height: CGFloat = .heightButton + 2 * .margin4x

    private let button = UIButton.appRed

    private var onTap: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        button.addTarget(self, action: #selector(_onTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTap() {
        onTap?()
    }

    func bind(title: String?, enabled: Bool = true, onTap: @escaping () -> ()) {
        button.setTitle(title, for: .normal)
        button.isEnabled = enabled
        self.onTap = onTap
    }

}
