import UIKit
import ThemeKit
import ComponentKit

class TransactionInfoTransactionIdCell: BaseThemeCell {
    private let titleView = TransactionInfoTitleView()
    private let idButton = ThemeButton()
    private let shareButton = ThemeButton()

    private var onTapId: (() -> ())?
    private var onTapShare: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        titleView.bind(text: "tx_info.transaction_id".localized)

        contentView.addSubview(idButton)
        idButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleView.snp.trailing)
            maker.centerY.equalToSuperview()
        }

        idButton.apply(style: .secondaryDefault)
        idButton.addTarget(self, action: #selector(_onTapId), for: .touchUpInside)

        contentView.addSubview(shareButton)
        shareButton.snp.makeConstraints { maker in
            maker.leading.equalTo(idButton.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        shareButton.apply(style: .secondaryIcon)
        shareButton.apply(secondaryIconImage: UIImage(named: "share_1_20"))
        shareButton.addTarget(self, action: #selector(_onTapShare), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapId() {
        onTapId?()
    }

    @objc private func _onTapShare() {
        onTapShare?()
    }

    func bind(value: String, onTapId: @escaping () -> (), onTapShare: @escaping () -> ()) {
        idButton.setTitle(value, for: .normal)

        self.onTapId = onTapId
        self.onTapShare = onTapShare
    }

}
