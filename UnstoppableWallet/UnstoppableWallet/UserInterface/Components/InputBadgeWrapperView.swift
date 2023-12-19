import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class InputBadgeWrapperView: UIView, ISizeAwareView {
    let badgeView = BadgeView()

    init() {
        super.init(frame: .zero)

        addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        badgeView.set(style: .small)
        badgeView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func width(containerWidth: CGFloat) -> CGFloat {
        guard let text = badgeView.text else {
            return 0
        }

        return text.size(containerWidth: containerWidth, font: badgeView.font).width
    }
}
