import UIKit
import SnapKit

class RequestErrorView: UIView {
    private let holderView =  UIView()
    private let imageView = UIImageView(image: UIImage(named: "Error Icon", in: Bundle(for: RequestErrorView.self), compatibleWith: nil))
    private let titleLabel = UILabel(frame: .zero)
    private var subtitleLabel: UILabel?
    private var button: RespondButton?
    private var linkView = FullTransactionLinkView()

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
            maker.top.equalTo(imageView.snp.bottom).offset(RequestErrorTheme.titleMargin)
            maker.leading.trailing.equalToSuperview()
        }
        titleLabel.numberOfLines = 1
        titleLabel.font = .cryptoBody
        titleLabel.textColor = .crypto_White_Black
        titleLabel.textAlignment = .center

        var bottomView: UIView = titleLabel
        if let subtitle = subtitle {
            let subtitleLabel = UILabel(frame: .zero)
            holderView.addSubview(subtitleLabel)
            subtitleLabel.snp.makeConstraints { maker in
                maker.top.equalTo(bottomView.snp.bottom).offset(RequestErrorTheme.subtitleMargin)
                maker.leading.trailing.equalToSuperview()
            }

            subtitleLabel.numberOfLines = 1
            subtitleLabel.font = .cryptoBody
            subtitleLabel.textColor = .cryptoRed
            subtitleLabel.textAlignment = .center
            subtitleLabel.text = subtitle
            bottomView = subtitleLabel
            self.subtitleLabel = subtitleLabel
        }
        if let buttonText = buttonText {
            let button = RespondButton(onTap: onTapButton)
            holderView.addSubview(button)

            button.borderWidth = 1 / UIScreen.main.scale
            button.borderColor = RequestErrorTheme.buttonBorderColor
            button.cornerRadius = RequestErrorTheme.buttonCornerRadius
            button.backgrounds = RequestErrorTheme.buttonBackground
            button.textColors = [.active: RequestErrorTheme.buttonIconColor, .selected: RequestErrorTheme.buttonIconColor]
            button.titleLabel.text = buttonText
            button.titleLabel.font = RequestErrorTheme.buttonFont
            button.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            button.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.top.equalTo(bottomView.snp.bottom).offset(RequestErrorTheme.buttonMargin)
                maker.height.equalTo(SendTheme.buttonSize)
            }
            button.titleLabel.snp.remakeConstraints { maker in
                maker.leading.equalToSuperview().offset(RequestErrorTheme.buttonTitleHorizontalMargin)
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalToSuperview().offset(-RequestErrorTheme.buttonTitleHorizontalMargin)
            }

            bottomView = button
        }
        holderView.addSubview(linkView)
        linkView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(bottomView.snp.bottom).offset(RequestErrorTheme.linkMargin)
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

    public func set(title: String?) {
        titleLabel.text = title
        setNeedsDisplay()
    }

    public func set(action: (() -> ())?) {
        button?.onTap = action
    }

}
