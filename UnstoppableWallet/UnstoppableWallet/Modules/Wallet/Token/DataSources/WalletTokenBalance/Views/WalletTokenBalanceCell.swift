import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class WalletTokenBalanceCell: UITableViewCell {
    private static let height: CGFloat = 147

    private let stackView = UIStackView()
    private let testnetImageView = UIImageView()
    private let coinIconView = BalanceCoinIconHolder()
    private let amountLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .blue
        selectionStyle = .none
        clipsToBounds = true

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin6)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = .margin6
        stackView.backgroundColor = .yellow

        stackView.addArrangedSubview(testnetImageView)
        testnetImageView.image = UIImage(named: "testnet_16")?.withRenderingMode(.alwaysTemplate)
        testnetImageView.tintColor = .themeRed50
        testnetImageView.contentMode = .top
        testnetImageView.snp.makeConstraints { maker in
            maker.height.equalTo(CGFloat.margin12)
        }

        testnetImageView.isHidden = true

        stackView.setCustomSpacing(.zero, after: testnetImageView)

        stackView.addArrangedSubview(coinIconView)
        coinIconView.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        stackView.addArrangedSubview(amountLabel)
        amountLabel.font = .title2R
        amountLabel.textColor = .themeLeah
        amountLabel.backgroundColor = .green

        stackView.addArrangedSubview(descriptionLabel)

        descriptionLabel.font = .body
        descriptionLabel.textColor = .themeGray
        descriptionLabel.backgroundColor = .purple
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: BalanceTopViewItem, onTapError: (() -> ())?) {
        testnetImageView.isHidden = viewItem.isMainNet
        coinIconView.bind(
                iconUrlString: viewItem.iconUrlString,
                placeholderIconName: viewItem.placeholderIconName,
                spinnerProgress: viewItem.syncSpinnerProgress,
                indefiniteSearchCircle: true, //viewItem.indefiniteSearchCircle,
                failViewVisible: viewItem.failedImageViewVisible,
                onTapError: onTapError
        )

        amountLabel.text = viewItem.primaryValue?.text
        descriptionLabel.text = "asadasdsa"
    }

}

extension WalletTokenBalanceCell {

    static func height(viewItem: BalanceTopViewItem?) -> CGFloat {
        var height: CGFloat = Self.height

        guard let viewItem else {
            return height
        }

        if !viewItem.isMainNet {
            height += .margin12
        }

        return HeaderAmountView.height
    }

}
