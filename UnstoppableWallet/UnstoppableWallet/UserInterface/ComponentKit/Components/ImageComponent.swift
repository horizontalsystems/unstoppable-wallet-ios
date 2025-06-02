import Kingfisher
import SnapKit
import UIKit

public class ImageComponent: UIView {
    public let imageView = UIImageView()

    public init(size: CGFloat) {
        super.init(frame: .zero)

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.size.equalTo(size)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var imageRatio: CGFloat? {
        if let image = imageView.image {
            return image.size.height / image.size.width
        }

        return nil
    }

    public func setImage(urlString: String?, placeholder: UIImage?) {
        imageView.kf.setImage(with: urlString.flatMap { URL(string: $0) }, placeholder: placeholder, options: [.scaleFactor(UIScreen.main.scale)])
    }
}
