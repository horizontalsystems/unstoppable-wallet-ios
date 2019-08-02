import UIKit
import SnapKit

class SendConfirmationSeparatorView: UIView {

    public init(height: CGFloat) {
        super.init(frame: .zero)

        backgroundColor = .clear

        self.snp.makeConstraints { maker in
            maker.height.equalTo(height)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}
