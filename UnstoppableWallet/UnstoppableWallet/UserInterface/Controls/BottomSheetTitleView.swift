import UIKit
import SnapKit
import ThemeKit

class BottomSheetTitleView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private weak var viewController: UIViewController?

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(60)
        }

        let stackView = UIStackView()

        stackView.spacing = .margin16
        stackView.alignment = .center

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin32)
            maker.top.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        stackView.addArrangedSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.size.equalTo(CGFloat.iconSize32)
        }

        let titleStackView = UIStackView()
        stackView.addArrangedSubview(titleStackView)

        titleStackView.axis = .vertical
        titleStackView.spacing = 1

        titleStackView.addArrangedSubview(titleLabel)

        titleLabel.font = .body
        titleLabel.textColor = .themeLeah

        titleStackView.addArrangedSubview(subtitleLabel)

        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeGray

        let closeButton = UIButton()

        addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(stackView.snp.trailing).offset(CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.centerY.equalTo(stackView)
            maker.size.equalTo(CGFloat.iconSize24 + 2 * CGFloat.margin8)
        }

        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
        closeButton.setImage(UIImage(named: "close_3_24"), for: .normal)
        closeButton.addTarget(self, action: #selector(_onTapClose), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTapClose() {
        viewController?.dismiss(animated: true)
    }

    func bind(image: Image? = nil, title: String, subtitle: String? = nil, viewController: UIViewController) {
        snp.updateConstraints { maker in
            maker.height.equalTo(subtitle != nil ? 72 : 60)
        }

        if let image = image {
            imageView.isHidden = false

            imageView.snp.updateConstraints { maker in
                maker.size.equalTo(subtitle != nil ? CGFloat.iconSize32 : CGFloat.iconSize24)
            }

            switch image {
            case .local(let image): imageView.image = image
            case let .remote(url, placeholder): imageView.setImage(withUrlString: url, placeholder: placeholder.flatMap { UIImage(named: $0) })
            }
        } else {
            imageView.isHidden = true
        }

        titleLabel.font = subtitle != nil ? .body : .headline2
        titleLabel.text = title

        if let subtitle = subtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.text = subtitle
        } else {
            subtitleLabel.isHidden = true
        }

        self.viewController = viewController
    }

}

extension BottomSheetTitleView {

    enum Image {
        case local(image: UIImage?)
        case remote(url: String, placeholder: String?)
    }

}
