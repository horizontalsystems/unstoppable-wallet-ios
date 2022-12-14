import Foundation
import UIKit
import ComponentKit
import HUD

class SwapPriceCell: BaseThemeCell {
    private static let buttonHeight: CGFloat = 28

    let titleLabel = UILabel()
    let priceButton = UIButton()
    let progressView = HUDProgressView(
            progress: 1,
            strokeLineWidth: 2,
            radius: 7.5,
            strokeColor: .themeJacob,
            donutColor: .themeSteel20,
            duration: 10
    )

    private var isReverted = false
    private var viewItem: PriceViewItem?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        titleLabel.text = "swap.price".localized
        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray

        wrapperView.addSubview(progressView)
        progressView.snp.makeConstraints { maker in
            maker.size.equalTo(CGFloat.iconSize20)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        progressView.clockwise = false

        wrapperView.addSubview(priceButton)
        priceButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalTo(progressView.snp.leading).offset(-CGFloat.margin8)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(Self.buttonHeight)
        }

        priceButton.titleLabel?.font = .subhead2
        priceButton.setContentHuggingPriority(.required, for: .horizontal)
        priceButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        priceButton.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)

        priceButton.setTitleColor(.themeLeah, for: .normal)
        priceButton.setTitleColor(.themeGray, for: .highlighted)
        priceButton.setTitleColor(.themeGray50, for: .disabled)
        priceButton.setTitleColor(.themeDark, for: .selected)
        priceButton.setTitleColor(.themeDark, for: [.selected, .highlighted])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        isReverted = !isReverted

        syncPrice()
    }

    private func syncPrice() {
        priceButton.setTitle(isReverted ? viewItem?.revertedPrice : viewItem?.price, for: .normal)
    }

}

extension SwapPriceCell {

    func set(item: PriceViewItem?) {
        viewItem = item

        syncPrice()
    }

    func set(progress: Float) {
        progressView.set(progress: progress)
    }

}

extension SwapPriceCell {

    struct PriceViewItem {
        let price: String?
        let revertedPrice: String?
    }

}
