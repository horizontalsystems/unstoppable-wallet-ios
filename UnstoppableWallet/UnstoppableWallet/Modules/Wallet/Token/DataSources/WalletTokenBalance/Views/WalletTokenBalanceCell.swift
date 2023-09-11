import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class WalletTokenBalanceCell: UITableViewCell {
    private let stackView = UIStackView()
    private let testnetImageView = UIImageView()
    private let coinIconView = BalanceCoinIconHolder()
    private let amountLabel = UILabel()
    private let amountButton = TextButtonComponent()
    private let descriptionLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(18)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = .margin6

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
        amountLabel.numberOfLines = 0
        amountLabel.textAlignment = .center
        amountLabel.isUserInteractionEnabled = true

        amountLabel.addSubview(amountButton)
        amountButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(descriptionLabel)

        descriptionLabel.font = .body
        descriptionLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: WalletTokenBalanceViewModel.ViewItem, onTapError: (() -> ())?) {
        testnetImageView.isHidden = viewItem.isMainNet
        coinIconView.bind(
                iconUrlString: viewItem.iconUrlString,
                placeholderIconName: viewItem.placeholderIconName,
                spinnerProgress: viewItem.syncSpinnerProgress,
                indefiniteSearchCircle: viewItem.indefiniteSearchCircle,
                failViewVisible: viewItem.failedImageViewVisible,
                onTapError: onTapError
        )

        amountLabel.text = viewItem.balanceValue?.text ?? "----"
        amountLabel.textColor = (viewItem.balanceValue?.dimmed ?? true) ? .themeGray : .themeLeah

        descriptionLabel.text = viewItem.descriptionValue?.text ?? "----"
        descriptionLabel.textColor = (viewItem.descriptionValue?.dimmed ?? true) ? .themeGray50 : .themeGray
    }

    var onTapAmount: (() -> ())? {
        get { amountButton.onTap }
        set { amountButton.onTap = newValue }
    }

}

extension WalletTokenBalanceCell {

    static func height(containerWidth: CGFloat, viewItem: WalletTokenBalanceViewModel.ViewItem?) -> CGFloat {
        var height: CGFloat = .margin24 + .iconSize32 + .margin12
        height += (viewItem?.balanceValue?.text ?? "----").height(forContainerWidth: containerWidth - 2 * .margin16, font: .title2R) + .margin6
        height += (viewItem?.descriptionValue?.text ?? "----").height(forContainerWidth: containerWidth - 2 * .margin16, font: .body) + .margin24

        if !(viewItem?.isMainNet ?? true) {
            height += .margin12
        }

        return height
    }

}
