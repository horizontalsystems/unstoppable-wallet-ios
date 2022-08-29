import UIKit
import ComponentKit

class NftAssetButtonCell: UITableViewCell {
    private let openSeaButton = PrimaryButton()
    private let moreButton = PrimaryCircleButton()

    private var onTapProvider: (() -> ())?
    private var onTapMore: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(openSeaButton)
        openSeaButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
        }

        openSeaButton.set(style: .gray)
        openSeaButton.setTitle("OpenSea", for: .normal) // todo: show corresponding provider name
        openSeaButton.addTarget(self, action: #selector(onTapOpenSeaButton), for: .touchUpInside)

        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { maker in
            maker.leading.equalTo(openSeaButton.snp.trailing).offset(CGFloat.margin8)
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

    @objc private func onTapOpenSeaButton() {
        onTapProvider?()
    }

    @objc private func onTapMoreButton() {
        onTapMore?()
    }

    func bind(onTapProvider: @escaping () -> (), onTapMore: @escaping () -> ()) {
        self.onTapProvider = onTapProvider
        self.onTapMore = onTapMore
    }

}
