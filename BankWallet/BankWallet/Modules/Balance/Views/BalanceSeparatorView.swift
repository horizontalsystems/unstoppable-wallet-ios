import UIKit
import SnapKit

class BalanceSeparatorView: UIView {
    static let height: CGFloat = 6

    init() {
        super.init(frame: .zero)

        clipsToBounds = true

        let separatorView = UIView()

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
