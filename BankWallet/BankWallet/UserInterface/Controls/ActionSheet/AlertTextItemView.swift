import UIKit
import ActionSheet
import SnapKit

class AlertTextItemView: BaseActionItemView {
    private let descriptionView = HighlightedDescriptionView()
    private let textLabel = UILabel()

    override var item: AlertTextItem? { _item as? AlertTextItem }

    override func initView() {
        super.initView()

        if item?.important ?? false {
            addSubview(descriptionView)
            descriptionView.snp.makeConstraints { maker in
                maker.top.bottom.equalToSuperview().inset(CGFloat.margin3x)
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            }
        } else {
            addSubview(textLabel)
            textLabel.font = .subhead1
            textLabel.textColor = .themeGray
            textLabel.numberOfLines = 0
            textLabel.snp.makeConstraints { maker in
                maker.top.bottom.equalToSuperview()
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            }
        }

        textLabel.text = item?.text
        descriptionView.bind(text: item?.text)
    }

}
