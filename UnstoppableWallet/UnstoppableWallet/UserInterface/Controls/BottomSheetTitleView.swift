import UIKit
import SnapKit
import ThemeKit

class BottomSheetTitleView: UIView {
    static let height: CGFloat = 64

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton()
    private let separatorView = UIView()

    var onTapClose: (() -> ())?

    init() {
        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(BottomSheetTitleView.height)
        }

        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.size.equalTo(24)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(iconImageView.snp.trailing).offset(CGFloat.margin3x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        titleLabel.font = .headline2
        titleLabel.textColor = .themeOz

        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin1x)
            maker.trailing.equalTo(titleLabel)
        }

        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeGray

        addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.size.equalTo(24 + 2 * CGFloat.margin2x)
        }

        closeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        closeButton.setImage(UIImage(named: "close_3_24"), for: .normal)
        closeButton.addTarget(self, action: #selector(_onTapClose), for: .touchUpInside)

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapClose() {
        onTapClose?()
    }

    func bind(title: String?, subtitle: String?, image: UIImage?, tintColor: UIColor? = nil) {
        bind(title: title, subtitle: subtitle)
        bind(image: image, tintColor: tintColor)
    }

    func bind(title: String?, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    func bind(image: UIImage?, tintColor: UIColor? = nil) {
        iconImageView.image = tintColor == nil ? image : image?.withRenderingMode(.alwaysTemplate)

        if let tintColor = tintColor {
            iconImageView.tintColor = tintColor
        }
    }

    func bind(imageUrl: String?, placeholder: UIImage?) {
        iconImageView.tintColor = nil
        iconImageView.kf.setImage(with: imageUrl.flatMap { URL(string: $0) }, placeholder: placeholder, options: [.scaleFactor(UIScreen.main.scale)])
    }

    var titleColor: UIColor {
        get { titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }

    var subtitleColor: UIColor {
        get { subtitleLabel.textColor }
        set { subtitleLabel.textColor = newValue }
    }

}
