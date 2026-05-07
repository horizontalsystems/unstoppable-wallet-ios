import SnapKit
import UIKit

public class BadgeComponent: UIView {
    public let badgeView = BadgeView()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
