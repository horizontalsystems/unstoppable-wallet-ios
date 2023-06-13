import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class WalletHeaderCell: UITableViewCell {
    private static let margins = UIEdgeInsets(top: .margin4, left: .margin16, bottom: .margin4, right: .margin16)

    private let amountView = HeaderAmountView()
    private let withdrawButton = PrimaryButton()
    private let depositButton = PrimaryButton()

    var onWithdraw: (() -> ())?
    var onDeposit: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(amountView)
        amountView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        contentView.addSubview(withdrawButton)
        withdrawButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin24)
            make.top.equalTo(amountView.snp.bottom).offset(CGFloat.margin4)
        }

        withdrawButton.set(style: .yellow)
        withdrawButton.setTitle("balance.withdraw".localized, for: .normal)
        withdrawButton.addTarget(self, action: #selector(onTapWithdraw), for: .touchUpInside)

        contentView.addSubview(depositButton)
        depositButton.snp.makeConstraints { make in
            make.leading.equalTo(withdrawButton.snp.trailing).offset(CGFloat.margin16)
            make.top.width.equalTo(withdrawButton)
            make.trailing.equalToSuperview().inset(CGFloat.margin24)
        }

        depositButton.set(style: .gray)
        depositButton.setTitle("balance.deposit".localized, for: .normal)
        depositButton.addTarget(self, action: #selector(onTapDeposit), for: .touchUpInside)

        let separatorView = UIView()
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel20
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    @objc private func onTapWithdraw() {
        onWithdraw?()
    }

    @objc private func onTapDeposit() {
        onDeposit?()
    }

    var onTapAmount: (() -> ())? {
        get { amountView.onTapAmount }
        set { amountView.onTapAmount = newValue }
    }

    var onTapConvertedAmount: (() -> ())? {
        get { amountView.onTapConvertedAmount }
        set { amountView.onTapConvertedAmount = newValue }
    }

    func bind(viewItem: WalletViewModel.HeaderViewItem) {
        amountView.set(amountText: viewItem.amount, expired: viewItem.amountExpired)
        amountView.set(convertedAmountText: viewItem.convertedValue, expired: viewItem.convertedValueExpired)
    }

}

extension WalletHeaderCell {

    static func height(viewItem: WalletViewModel.HeaderViewItem?) -> CGFloat {
        guard let viewItem else {
            return HeaderAmountView.height
        }

        return HeaderAmountView.height + (viewItem.buttonsVisible ? .margin4 + PrimaryButton.height + .margin16 : 0)
    }

}
