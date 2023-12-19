import ComponentKit
import SnapKit
import ThemeKit
import UIKit

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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var image: UIImage? {
        get { customImageView.image }
        set { customImageView.image = newValue }
    }
}

extension ImageCell {
    static func height(containerWidth: CGFloat, imageSize: CGSize? = nil) -> CGFloat {
        guard let imageSize else {
            return max(0, containerWidth - 2 * horizontalPadding)
        }

        return imageSize.height
    }
}
