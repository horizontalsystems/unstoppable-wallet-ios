import UIKit
import ThemeKit

class TransactionInfoCopyCell: ThemeCell {
    private let titleView = TransactionInfoTitleView()
    private let copyButton = ThemeButton()

    private var onTapCopy: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleView.snp.trailing)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        copyButton.apply(style: .secondaryIcon)
        copyButton.apply(secondaryIconImage: UIImage(named: "Address Field Copy Icon"))
        copyButton.addTarget(self, action: #selector(_onTapCopy), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapCopy() {
        onTapCopy?()
    }

    func bind(title: String, onTapCopy: @escaping () -> ()) {
        super.bind(bottomSeparatorVisible: true)

        titleView.bind(text: title)
        self.onTapCopy = onTapCopy
    }

}
