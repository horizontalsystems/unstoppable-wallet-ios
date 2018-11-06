import UIKit
import GrouviActionSheet

class DepositCopyButtonItem: BaseButtonItem {
    override var backgroundStyle: RespondButton.Style { return ButtonTheme.greenBackgroundOnWhiteBackgroundDictionary }
    override var textStyle: RespondButton.Style { return ButtonTheme.textColorOnWhiteBackgroundDictionary }
    override var title: String { return "alert.copy".localized }

    init(tag: Int? = nil, hidden: Bool = false, required: Bool = false, onTap: @escaping (() -> ())) {
        super.init(cellType: DepositCopyButtonItemView.self, tag: tag, hidden: hidden, required: required)

        self.onTap = onTap
        height = DepositTheme.copyButtonItemHeight
    }

}
