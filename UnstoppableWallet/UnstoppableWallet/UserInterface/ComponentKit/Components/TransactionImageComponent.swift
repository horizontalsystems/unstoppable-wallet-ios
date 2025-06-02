import HUD
import Kingfisher
import SnapKit
import UIKit

public class TransactionImageComponent: UIView {
    private let spinner = HUDProgressView(
        progress: 0,
        strokeLineWidth: 2,
        radius: 21,
        strokeColor: .themeGray,
        donutColor: .themeSteel10,
        duration: 2
    )

    private let imageView = UIImageView()

    private let doubleImageWrapper = UIView()
    private let backImageView = UIImageView()
    private let frontImageMask = UIView()
    private let frontImageView = UIImageView()

    init() {
        super.init(frame: .zero)

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.size.equalTo(44)
        }

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.center.equalTo(spinner)
            maker.size.equalTo(CGFloat.iconSize32)
        }

        addSubview(doubleImageWrapper)
        doubleImageWrapper.snp.makeConstraints { maker in
            maker.center.equalTo(spinner)
            maker.width.equalTo(32)
            maker.height.equalTo(36)
        }

        doubleImageWrapper.addSubview(backImageView)
        backImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize24)
        }

        backImageView.contentMode = .scaleAspectFill

        doubleImageWrapper.addSubview(frontImageMask)
        doubleImageWrapper.addSubview(frontImageView)

        frontImageView.snp.makeConstraints { maker in
            maker.trailing.bottom.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize24)
        }

        frontImageView.contentMode = .scaleAspectFill

        frontImageMask.snp.makeConstraints { maker in
            maker.size.equalTo(frontImageView)
            maker.center.equalTo(frontImageView).offset(-1)
        }

        frontImageMask.backgroundColor = .themeTyler
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(progress: Float?) {
        if let progress {
            spinner.isHidden = false
            spinner.set(progress: progress)
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
            spinner.isHidden = true
        }
    }

    public func set(image: UIImage?, contentMode: UIView.ContentMode = .scaleAspectFill) {
        doubleImageWrapper.isHidden = true
        imageView.isHidden = false

        imageView.contentMode = contentMode
        imageView.image = image
        imageView.cornerRadius = .cornerRadius4
    }

    public func setImage(url: String?, alternativeUrl: String?, placeholder: UIImage?, type: ImageType = .squircle) {
        doubleImageWrapper.isHidden = true
        imageView.isHidden = false

        imageView.contentMode = .scaleAspectFill
        imageView.setImage(url: url, alternativeUrl: alternativeUrl, placeholder: placeholder)

        switch type {
        case .circle:
            imageView.cornerRadius = CGFloat.iconSize32 / 2
        case .squircle:
            imageView.cornerRadius = .cornerRadius4
        }
    }

    public func setDoubleImage(frontType: ImageType, frontUrl: String?, frontAlternativeUrl: String?, frontPlaceholder: UIImage?, backType: ImageType, backUrl: String?, backAlternativeUrl: String?, backPlaceholder: UIImage?) {
        imageView.isHidden = true
        doubleImageWrapper.isHidden = false

        switch frontType {
        case .circle:
            frontImageView.cornerRadius = CGFloat.iconSize24 / 2
            frontImageMask.cornerRadius = CGFloat.iconSize24 / 2
        case .squircle:
            frontImageView.cornerRadius = .cornerRadius4
            frontImageMask.cornerRadius = .cornerRadius4
        }

        switch backType {
        case .circle:
            backImageView.cornerRadius = CGFloat.iconSize24 / 2
        case .squircle:
            backImageView.cornerRadius = .cornerRadius4
        }

        frontImageView.setImage(url: frontUrl, alternativeUrl: frontAlternativeUrl, placeholder: frontPlaceholder)
        backImageView.setImage(url: backUrl, alternativeUrl: backAlternativeUrl, placeholder: backPlaceholder)
    }
}

public extension TransactionImageComponent {
    enum ImageType {
        case circle
        case squircle
    }
}
