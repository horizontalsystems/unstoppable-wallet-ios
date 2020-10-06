import UIKit
import SnapKit
import ThemeKit

class RequestErrorViewNew: UIView {
    private let holderView =  UIView()
    private let imageView = UIImageView()
    private var label = UILabel()

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init() {
        super.init(frame: CGRect.zero)

        backgroundColor = .clear

        addSubview(holderView)
        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        holderView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.centerX.equalToSuperview()
        }

        holderView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        label.numberOfLines = 1
        label.font = .subhead2
        label.textColor = .themeGray
        label.textAlignment = .center
    }

    public func bind(image: UIImage?, text: String? = nil) {
        imageView.image = image
        label.text = text
    }

}
