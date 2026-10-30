
import SnapKit
import UIKit

class PlaceholderView: UIView {
    private let stackView = UIStackView()
    private let topSpacer = UIView()
    private let bottomSpacer = UIView()

    private let imageWrapper = UIView()
    private let imageView = UIImageView()
    private let label = UILabel()

    init(layoutType: LayoutType = .upperMiddle) {
        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.width.equalTo(264)
        }

        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = .margin32

        addSubview(topSpacer)
        topSpacer.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(stackView.snp.top)
        }

        addSubview(bottomSpacer)
        bottomSpacer.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview().inset(layoutType.bottomInset)
            maker.top.equalTo(stackView.snp.bottom)
            maker.height.equalTo(topSpacer).multipliedBy(layoutType.multiplier)
        }

        stackView.addArrangedSubview(imageWrapper)
        imageWrapper.addSubview(imageView)

        imageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.bottom.equalToSuperview()
            maker.size.equalTo(100)
        }

        imageView.contentMode = .center
        imageView.cornerRadius = 50
        imageView.backgroundColor = .themeBlade

        stackView.addArrangedSubview(label)

        label.isHidden = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .subhead2
        label.textColor = .themeGray
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var image: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue?.withTintColor(.themeGray) }
    }

    var text: String? {
        get { label.text }
        set {
            label.text = newValue
            label.isHidden = newValue == nil
        }
    }
}

extension PlaceholderView {
    enum LayoutType {
        case upperMiddle
        case keyboard
        case bottom

        var multiplier: CGFloat {
            switch self {
            case .upperMiddle, .keyboard: return 1.6
            case .bottom: return 0.4
            }
        }

        var bottomInset: CGFloat {
            switch self {
            case .upperMiddle, .bottom: return 0
            case .keyboard: return 258 // approximate keyboard height, exact value is not required
            }
        }
    }
}
