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
        nftImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.bottom.equalToSuperview()
        }

        nftImageView.cornerRadius = .cornerRadius12
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(url: String) {
        nftImageView.setImage(url: url)
    }

    var currentImage: UIImage? {
        nftImageView.currentImage
    }

}

extension NftAssetImageCell {

    static func height(containerWidth: CGFloat, ratio: CGFloat) -> CGFloat {
        let imageWidth = max(0, containerWidth - 2 * horizontalMargin)
        return imageWidth * ratio
    }

}
