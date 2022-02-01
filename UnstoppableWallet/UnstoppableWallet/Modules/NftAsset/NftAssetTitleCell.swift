import UIKit
import ComponentKit

class NftAssetTitleCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin16
    private static let subtitleTopMargin: CGFloat = .margin12
    private static let buttonTopMargin: CGFloat = .margin24
    private static let titleFont: UIFont = .headline1
    private static let subtitleFont: UIFont = .subhead1

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let openSeaButton = ThemeButton()
    private let moreButton = ThemeButton()

    private var onTapOpenSea: (() -> ())?
    private var onTapMore: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalToSuperview()
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = Self.titleFont
        titleLabel.textColor = .themeLeah

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.equalTo(titleLabel.snp.bottom).offset(Self.subtitleTopMargin)
        }

        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = Self.subtitleFont
        subtitleLabel.textColor = .themeGray

        contentView.addSubview(openSeaButton)
        openSeaButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(subtitleLabel.snp.bottom).offset(Self.buttonTopMargin)
            maker.height.equalTo(CGFloat.heightButton)
        }

        openSeaButton.apply(style: .primaryGray)
        openSeaButton.setTitle("OpenSea", for: .normal)
        openSeaButton.addTarget(self, action: #selector(onTapOpenSeaButton), for: .touchUpInside)

        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { maker in
            maker.leading.equalTo(openSeaButton.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalTo(openSeaButton)
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

    func bind(title: String, subtitle: String, onTapOpenSea: @escaping () -> (), onTapMore: @escaping () -> ()) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        self.onTapOpenSea = onTapOpenSea
        self.onTapMore = onTapMore
    }

}

extension NftAssetTitleCell {

    static func height(containerWidth: CGFloat, title: String, subtitle: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalMargin

        let titleHeight = title.height(forContainerWidth: textWidth, font: titleFont)
        let subtitleHeight = subtitle.height(forContainerWidth: textWidth, font: subtitleFont)

        return titleHeight + subtitleTopMargin + subtitleHeight + buttonTopMargin + .heightButton
    }

}
