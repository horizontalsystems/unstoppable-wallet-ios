import SnapKit
import ThemeKit
import UIKit

public class MultiTextComponent: UIView {
    private let titleStackView = UIStackView()
    private let subtitleStackView = UIStackView()

    public let title = TextComponent()
    public let titleBadge = BadgeView()
    public let titleImageLeft = ImageComponent(size: .iconSize20)
    public let titleImageRight = ImageComponent(size: .iconSize20)
    public let titleSpacingView = UIView()

    public let subtitleBadge = BadgeView()
    public let subtitleLeft = TextComponent()
    public let subtitleRight = TextComponent()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        let container = UIView()

        addSubview(container)
        container.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        container.addSubview(titleStackView)
        titleStackView.snp.makeConstraints { maker in
            maker.leading.top.equalToSuperview()
            maker.trailing.equalToSuperview()
        }

        titleStackView.alignment = .center

        container.addSubview(subtitleStackView)
        subtitleStackView.snp.makeConstraints { maker in
            maker.leading.bottom.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalTo(titleStackView.snp.bottom).offset(3)
        }

        subtitleStackView.alignment = .center

        titleStackView.addArrangedSubview(title)
        titleStackView.setCustomSpacing(.margin6, after: title)

        titleStackView.addArrangedSubview(titleBadge)
        titleStackView.setCustomSpacing(.margin6, after: titleBadge)
        titleBadge.set(style: .small)

        titleStackView.addArrangedSubview(titleImageLeft)
        titleStackView.setCustomSpacing(.margin6, after: titleImageLeft)

        titleStackView.addArrangedSubview(titleImageRight)

        titleStackView.addArrangedSubview(titleSpacingView)

        subtitleStackView.addArrangedSubview(subtitleBadge)
        subtitleStackView.setCustomSpacing(.margin8, after: subtitleBadge)
        subtitleBadge.set(style: .small)

        subtitleStackView.addArrangedSubview(subtitleLeft)
        subtitleStackView.setCustomSpacing(.margin4, after: subtitleLeft)

        subtitleLeft.setContentCompressionResistancePriority(.required, for: .horizontal)
        subtitleLeft.setContentHuggingPriority(.required, for: .horizontal)

        subtitleStackView.addArrangedSubview(subtitleRight)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var subtitle: TextComponent {
        subtitleRight
    }

    public func set(style: Style) {
        title.isHidden = true
        titleBadge.isHidden = true
        titleImageLeft.isHidden = true
        titleImageRight.isHidden = true
        subtitleBadge.isHidden = true
        subtitleLeft.isHidden = true
        subtitleRight.isHidden = true

        switch style {
        case .m1:
            title.isHidden = false
            subtitleRight.isHidden = false
        case .m2:
            title.isHidden = false
            subtitleLeft.isHidden = false
            subtitleRight.isHidden = false
        case .m3:
            title.isHidden = false
            subtitleBadge.isHidden = false
            subtitleRight.isHidden = false
        case .m4:
            title.isHidden = false
            titleBadge.isHidden = false
            subtitleLeft.isHidden = false
            subtitleRight.isHidden = false
        case .m5:
            title.isHidden = false
            titleImageLeft.isHidden = false
            subtitleRight.isHidden = false
        case .m6:
            title.isHidden = false
            titleImageLeft.isHidden = false
            titleImageRight.isHidden = false
            subtitleRight.isHidden = false
        case .m7:
            title.isHidden = false
            titleBadge.isHidden = false
            subtitleRight.isHidden = false
        }
    }
}

public extension MultiTextComponent {
    enum Style {
        case m1
        case m2
        case m3
        case m4
        case m5
        case m6
        case m7
    }
}
