import UIKit
import ComponentKit

class NftAssetImageCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin16

    private let nftImageView = NftImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(nftImageView)

        nftImageView.layer.cornerCurve = .continuous
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(nftImage: NftImage, cornerRadius: CGFloat = .cornerRadius12) {
        nftImageView.snp.remakeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.bottom.equalToSuperview()
            maker.height.equalTo(nftImageView.snp.width).multipliedBy(nftImage.ratio)
        }

        nftImageView.cornerRadius = cornerRadius
        nftImageView.set(nftImage: nftImage)
    }

    var currentImage: UIImage? {
        nftImageView.currentImage
    }

}

extension NftAssetImageCell {

    static func height(containerWidth: CGFloat, maxHeight: CGFloat, ratio: CGFloat) -> CGFloat {
        let imageWidth = max(0, containerWidth - 2 * horizontalMargin)
        return min(120, imageWidth * ratio)
    }

    static func height(containerWidth: CGFloat, ratio: CGFloat) -> CGFloat {
        let imageWidth = max(0, containerWidth - 2 * horizontalMargin)
        return imageWidth * ratio
    }

}
