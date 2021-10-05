import UIKit
import SnapKit
import ThemeKit
import ComponentKit

open class MarketListErrorView: UIView {
    private let wrapperView = UIView()
    private let imageView = UIImageView()
    private let label = UILabel()
    private let button = ThemeButton()

    var onTapRetry: (() -> ())?

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
        }

        imageView.image = UIImage(named: "attention_48")

        wrapperView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin16)
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
            maker.width.equalTo(145)
        }

        button.apply(style: .secondaryDefault)
        button.setTitle("button.retry".localized, for: .normal)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTapRetry?()
    }

    public var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

}
