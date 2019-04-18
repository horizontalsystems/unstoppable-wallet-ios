import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class SendConfirmationAddressItemView: BaseActionItemView {
    let hashView = HashView()

    override var item: SendConfirmationAddressItem? { return _item as? SendConfirmationAddressItem }

    override func initView() {
        super.initView()

        backgroundColor = SendTheme.itemBackground

        addSubview(hashView)
        hashView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }
    }

    override func updateView() {
        super.updateView()

        hashView.bind(value: item?.address, showExtra: .icon, onTap: item?.onHashTap)
    }

}
