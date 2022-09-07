import UIKit
import ComponentKit

class NftAssetButtonCell: UITableViewCell {
    private let providerButton = PrimaryButton()
    private let moreButton = PrimaryCircleButton()

    private var onTapProvider: (() -> ())?
    private var onTapMore: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(providerButton)
        providerButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
        }

        providerButton.set(style: .gray)
        providerButton.addTarget(self, action: #selector(onTapProviderButton), for: .touchUpInside)

        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { maker in
            maker.leading.equalTo(providerButton.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        moreButton.set(style: .gray)
        moreButton.set(image: UIImage(named: "more_24"))
        moreButton.addTarget(self, action: #selector(onTapMoreButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapProviderButton() {
        onTapProvider?()
    }

    @objc private func onTapMoreButton() {
        onTapMore?()
    }

    func bind(providerTitle: String?, onTapProvider: @escaping () -> (), onTapMore: @escaping () -> ()) {
        providerButton.setTitle(providerTitle, for: .normal)

        self.onTapProvider = onTapProvider
        self.onTapMore = onTapMore
    }

}
