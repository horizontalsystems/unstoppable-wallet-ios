import UIKit
import SnapKit

class RequestErrorView: UIView {
    private let holderView =  UIView()
    private let imageView = UIImageView(image: UIImage(named: "Error Icon", in: Bundle(for: RequestErrorView.self), compatibleWith: nil))
    private let titleLabel = UILabel(frame: .zero)
    private var subtitleLabel: UILabel?
    private var button: UIButton?
    private var linkView = FullTransactionLinkView()

    private var action: (() -> ())?

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init(subtitle: String?, buttonText: String?, linkText: String, onTapButton: (() -> ())? = nil, onTapLink: (() -> ())? = nil) {
        super.init(frame: CGRect.zero)

        backgroundColor = .clear

        holderView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.centerX.equalToSuperview()
        }

        holderView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin6x)
            maker.leading.trailing.equalToSuperview()
        }

        titleLabel.numberOfLines = 1
        titleLabel.font = .appBody
        titleLabel.textColor = .crypto_White_Black
        titleLabel.textAlignment = .center

        var bottomView: UIView = titleLabel
        if let subtitle = subtitle {
            let subtitleLabel = UILabel(frame: .zero)
            holderView.addSubview(subtitleLabel)
            subtitleLabel.snp.makeConstraints { maker in
                maker.top.equalTo(bottomView.snp.bottom).offset(CGFloat.margin1x)
                maker.leading.trailing.equalToSuperview()
            }

            subtitleLabel.numberOfLines = 1
            subtitleLabel.font = .appBody
            subtitleLabel.textColor = .appLucian
            subtitleLabel.textAlignment = .center
            subtitleLabel.text = subtitle
            bottomView = subtitleLabel
            self.subtitleLabel = subtitleLabel
        }
        if let buttonText = buttonText {
            let button = UIButton.appSecondary
            holderView.addSubview(button)

            button.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(bottomView.snp.bottom).offset(CGFloat.margin4x)
                maker.height.equalTo(CGFloat.heightButtonSecondary)
            }

            button.setTitle(buttonText, for: .normal)
            button.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
            action = onTapButton
            bottomView = button
        }
        holderView.addSubview(linkView)
        linkView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(bottomView.snp.bottom).offset(CGFloat.margin6x)
        }
        linkView.bind(text: linkText, onTap: onTapLink)
        bottomView = linkView

        addSubview(holderView)
        holderView.snp.makeConstraints { maker in
            maker.bottom.equalTo(bottomView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.center.equalToSuperview()
        }
    }

    @objc private func tapButton() {
        action?()
    }

    public func set(title: String?) {
        titleLabel.text = title
        setNeedsDisplay()
    }

    public func set(action: (() -> ())?) {
        self.action = action
    }

}
