import UIKit
import ThemeKit
import ComponentKit
import SnapKit

class ImageCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin16

    private let customImageView = UIImageView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(customImageView)
        customImageView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(Self.horizontalPadding)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var image: UIImage? {
        get { customImageView.image }
        set { customImageView.image = newValue }
    }

}

extension ImageCell {

    static func height(containerWidth: CGFloat, imageSize: CGSize? = nil) -> CGFloat {
        guard let imageSize = imageSize else {
            return max(0, containerWidth - 2 * Self.horizontalPadding)
        }

        return imageSize.height
    }

}
