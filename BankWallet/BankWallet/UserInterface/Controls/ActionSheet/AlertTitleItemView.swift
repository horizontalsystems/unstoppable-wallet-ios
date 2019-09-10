import UIKit
import ActionSheet
import SnapKit

class AlertTitleItemView: BaseActionItemView {
    private let titleView = AlertTitleView(frame: .zero)

    override var item: AlertTitleItem? { return _item as? AlertTitleItem }

    override func initView() {
        super.initView()

        addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        titleView.bind(title: item?.title, subtitle: item?.subtitle, image: item?.icon, tintColor: item?.iconTintColor, onClose: { [weak self] in
            self?.item?.onClose?()
        })

        item?.bindSubtitle = { [weak self] subtitle in
            self?.titleView.bind(subtitle: subtitle)
        }
    }

}
