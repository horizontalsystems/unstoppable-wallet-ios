import UIKit
import SnapKit
import ThemeKit
import ComponentKit

open class ErrorMessageView: UIView {
    private static let imageSize: CGFloat = 100

    private let wrapperView = UIView()
    private let imageView = UIImageView()
    private let label = UILabel()
    private let button = ThemeButton()

    var onTapButton: (() -> ())?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.centerY.equalToSuperview()
        }

        wrapperView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.centerX.equalToSuperview()
            maker.size.equalTo(Self.imageSize)
        }

        imageView.layer.cornerRadius = Self.imageSize / 2
        imageView.backgroundColor = .themeRaina
        imageView.tintColor = .themeGray
        imageView.contentMode = .center

        wrapperView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin32)
        }

        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .subhead2
        label.textColor = .themeGray

        wrapperView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(label.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalToSuperview()
        }

        button.apply(style: .secondaryDefault)
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTap() {
        onTapButton?()
    }

    public var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    public var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue?.withRenderingMode(.alwaysTemplate) }
    }

    public func setButton(title: String?) {
        button.setTitle(title, for: .normal)
    }

}
