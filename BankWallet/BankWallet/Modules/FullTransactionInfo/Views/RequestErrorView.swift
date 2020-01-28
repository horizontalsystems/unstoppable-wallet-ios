import UIKit
import SnapKit

class RequestErrorView: UIView {
    private let holderView =  UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel(frame: .zero)
    private var subtitleLabel = UILabel()
    private var button = UIButton.appSecondary
    private var linkView = FullTransactionLinkView()

    private var action: (() -> ())?

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init() {
        super.init(frame: CGRect.zero)

        backgroundColor = .clear

        addSubview(holderView)

        holderView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.centerX.equalToSuperview()
        }

        holderView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        titleLabel.numberOfLines = 1
        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray
        titleLabel.textAlignment = .center

        holderView.addSubview(subtitleLabel)
        holderView.addSubview(button)
        holderView.addSubview(linkView)

        updateConstraints(showSubtitle: false, showButton: false)

        subtitleLabel.numberOfLines = 1
        subtitleLabel.font = .body
        subtitleLabel.textColor = .themeLucian
        subtitleLabel.textAlignment = .center

        holderView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.center.equalToSuperview()
        }
    }

    func updateConstraints(showSubtitle: Bool, showButton: Bool) {
        if showSubtitle {
            subtitleLabel.snp.remakeConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin4x)
                maker.leading.trailing.equalToSuperview()
            }
        } else {
            subtitleLabel.snp.remakeConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom)
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(0)
            }
        }
        if showButton {
            button.snp.remakeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(subtitleLabel.snp.bottom).offset(CGFloat.margin4x)
                maker.height.equalTo(CGFloat.heightButtonSecondary)
            }
        } else {
            button.snp.remakeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(subtitleLabel.snp.bottom)
                maker.height.equalTo(0)
            }
        }
        linkView.snp.remakeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(button.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
        }
    }

    @objc private func tapButton() {
        action?()
    }

    public func bind(image: UIImage?, title: String, subtitle: String? = nil, buttonText: String? = nil, linkText: String, onTapButton: (() -> ())? = nil, onTapLink: (() -> ())? = nil) {
        imageView.image = image
        titleLabel.text = title

        subtitleLabel.text = subtitle
        button.setTitle(buttonText, for: .normal)

        linkView.bind(text: linkText, onTap: onTapLink)
        action = onTapButton

        updateConstraints(showSubtitle: subtitle != nil, showButton: buttonText != nil)
        setNeedsDisplay()
    }

}
