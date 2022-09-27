import UIKit
import ComponentKit

class NftAssetButtonCell: UITableViewCell {
    private let providerButton = PrimaryButton()
    private let sendButton = PrimaryButton()
    private let moreButton = PrimaryCircleButton()

    private let stackView = UIStackView()

    private var onTapSend: (() -> ())?
    private var onTapProvider: (() -> ())?
    private var onTapMore: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        stackView.addArrangedSubview(sendButton)
        stackView.addArrangedSubview(providerButton)
        stackView.addArrangedSubview(moreButton)

        stackView.spacing = .margin8
        stackView.alignment = .fill
        stackView.distribution = .fill

        sendButton.set(style: .yellow)
        sendButton.addTarget(self, action: #selector(onTapSendButton), for: .touchUpInside)
        sendButton.setTitle("button.send".localized, for: .normal)

        providerButton.set(style: .gray)
        providerButton.addTarget(self, action: #selector(onTapProviderButton), for: .touchUpInside)

        moreButton.set(style: .gray)
        moreButton.set(image: UIImage(named: "more_24"))
        moreButton.addTarget(self, action: #selector(onTapMoreButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSendButton() {
        onTapSend?()
    }

    @objc private func onTapProviderButton() {
        onTapProvider?()
    }

    @objc private func onTapMoreButton() {
        onTapMore?()
    }

    func bind(providerTitle: String?, onTapSend: (() -> ())?, onTapProvider: @escaping () -> (), onTapMore: @escaping () -> ()) {
        providerButton.setTitle(providerTitle, for: .normal)

        sendButton.isHidden = onTapSend == nil
        providerButton.isHidden = onTapSend != nil

        self.onTapSend = onTapSend
        self.onTapProvider = onTapProvider
        self.onTapMore = onTapMore
    }

}
