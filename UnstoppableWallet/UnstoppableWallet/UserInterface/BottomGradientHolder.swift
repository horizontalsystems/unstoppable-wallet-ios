import UIKit
import UIExtensions
import SnapKit

class BottomGradientHolder: GradientView {
    var contentView = UIView()

    init() {
        let holderBackground: UIColor = .themeTyler
        super.init(gradientHeight: .margin4x, fromColor: holderBackground.withAlphaComponent(0), toColor: holderBackground)

        super.addSubview(contentView)
        contentView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func addSubview(_ view: UIView) {
        contentView.addSubview(view)
    }

}
