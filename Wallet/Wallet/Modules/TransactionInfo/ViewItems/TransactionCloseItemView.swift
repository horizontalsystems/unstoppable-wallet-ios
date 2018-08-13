import Foundation
import GrouviActionSheet

class TransactionCloseItemView: BaseButtonItemView {

    override var item: TransactionCloseItem? { return _item as? TransactionCloseItem }

    override func initView() {
        super.initView()

        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

}
