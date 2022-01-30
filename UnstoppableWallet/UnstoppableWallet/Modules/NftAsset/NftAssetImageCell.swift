import UIKit
import ComponentKit
import Kingfisher

class NftAssetImageCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin16

    private let assetImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(assetImageView)
        assetImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            maker.top.bottom.equalToSuperview()
        }

        assetImageView.contentMode = .scaleAspectFill
        assetImageView.cornerRadius = .cornerRadius12
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(url: String) {
        assetImageView.kf.setImage(with: URL(string: url), options: [.transition(.fade(0.5))])
    }

}

extension NftAssetImageCell {

    static func height(containerWidth: CGFloat, ratio: CGFloat) -> CGFloat {
        let imageWidth = max(0, containerWidth - 2 * horizontalMargin)
        return imageWidth * ratio
    }

}
