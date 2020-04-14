import UIKit
import ActionSheet
import SnapKit

class AlertTextItemView: BaseActionItemView {
    private let descriptionView = HighlightedDescriptionView()

    override var item: AlertTextItem? { return _item as? AlertTextItem }

    override func initView() {
        super.initView()

        addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        descriptionView.bind(text: item?.text)
    }

}
