import UIKit
import SnapKit
import ThemeKit
import Kingfisher

class MarkdownImageCell: UITableViewCell {
    private static let verticalPadding: CGFloat = .margin3x

    private let placeholderImageView = UIImageView()
    private let markdownImageView = UIImageView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(placeholderImageView)
        placeholderImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview() // constraints are remade in bind
        }

        placeholderImageView.image = UIImage(named: "image_placeholder_48")
        placeholderImageView.contentMode = .center
        placeholderImageView.backgroundColor = .themeSteel20

        contentView.addSubview(markdownImageView)
        markdownImageView.snp.makeConstraints { maker in
            maker.edges.equalTo(placeholderImageView)
        }

        markdownImageView.contentMode = .scaleAspectFill
        markdownImageView.clipsToBounds = true
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(imageUrl: URL, type: MarkdownImageType, tight: Bool) {
        placeholderImageView.isHidden = false

        markdownImageView.kf.setImage(with: imageUrl) { [weak self] result in
            switch result {
            case .success: self?.placeholderImageView.isHidden = true
            default: ()
            }
        }

        placeholderImageView.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview().inset(tight ? 0 : MarkdownImageCell.verticalPadding)
        }
    }

}

extension MarkdownImageCell {

    static func height(containerWidth: CGFloat, type: MarkdownImageType, tight: Bool) -> CGFloat {
        var imageHeight: CGFloat

        switch type {
        case .landscape: imageHeight = containerWidth / 4 * 3
        case .portrait: imageHeight = containerWidth / 9 * 16
        case .square: imageHeight = containerWidth
        }

        if !tight {
            imageHeight += 2 * verticalPadding
        }

        return imageHeight
    }

}
