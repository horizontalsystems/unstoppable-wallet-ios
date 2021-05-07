import UIKit
import ThemeKit
import ComponentKit

class TransactionInfoShareCell: BaseThemeCell {
    private let titleView = TransactionInfoTitleView()
    private let shareButton = ThemeButton()

    private var onTapShare: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(shareButton)
        shareButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleView.snp.trailing)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        shareButton.apply(style: .secondaryIcon)
        shareButton.apply(secondaryIconImage: UIImage(named: "share_1_20"))
        shareButton.addTarget(self, action: #selector(_onTapCopy), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapCopy() {
        onTapShare?()
    }

    func bind(title: String, onTapShare: @escaping () -> ()) {
        titleView.bind(text: title)
        self.onTapShare = onTapShare
    }

}
