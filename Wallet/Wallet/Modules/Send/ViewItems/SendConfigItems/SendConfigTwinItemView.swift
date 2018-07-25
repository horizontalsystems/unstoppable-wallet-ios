import Foundation
import GrouviActionSheet

class SendConfigTwinItemView: BaseTwinItemView {

    override var firstItemInstance: BaseActionItemView {
        return SendAmountItemView(item: BaseActionItem())
    }
    override var secondItemInstance: BaseActionItemView {
        return SendReferenceItemView(item: BaseActionItem())
    }

    override func updateView() {
        super.updateView()
//        let showSearch = !(item?.showFirstItem ?? true)
//
//        if let field = (secondItemView as? CommentItemView)?.commentField, !field.isFirstResponder, showSearch {
//            field.becomeFirstResponder()
//        }
    }

}
