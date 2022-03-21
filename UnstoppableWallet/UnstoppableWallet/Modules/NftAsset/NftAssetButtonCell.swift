import UIKit
import ComponentKit

class NftAssetButtonCell: UITableViewCell {
    private let openSeaButton = ThemeButton()
    private let moreButton = ThemeButton()

    private var onTapOpenSea: (() -> ())?
    private var onTapMore: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(openSeaButton)
        openSeaButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        openSeaButton.apply(style: .primaryGray)
        openSeaButton.setTitle("OpenSea", for: .normal)
        openSeaButton.addTarget(self, action: #selector(onTapOpenSeaButton), for: .touchUpInside)

        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { maker in
            maker.leading.equalTo(openSeaButton.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.size.equalTo(CGFloat.heightButton)
        }

        moreButton.apply(style: .primaryIconGray)
        moreButton.setImage(UIImage(named: "more_24"), for: .normal)
        moreButton.addTarget(self, action: #selector(onTapMoreButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapOpenSeaButton() {
        onTapOpenSea?()
    }

    @objc private func onTapMoreButton() {
        onTapMore?()
    }

    func bind(onTapOpenSea: @escaping () -> (), onTapMore: @escaping () -> ()) {
        self.onTapOpenSea = onTapOpenSea
        self.onTapMore = onTapMore
    }

}
