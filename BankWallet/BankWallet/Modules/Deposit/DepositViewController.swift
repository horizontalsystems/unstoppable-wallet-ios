import UIKit
import ActionSheet
import ThemeKit

class DepositViewController: WalletActionSheetController {
    private let delegate: IDepositViewDelegate

    private var currentPage = 0
    private var pagingItem: PagingDotsItem?

    init(delegate: IDepositViewDelegate) {
        self.delegate = delegate
        super.init()

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        let items = delegate.addressItems

        let depositItem = DepositCollectionItem(addresses: items, tag: 0, onPageChange: { [weak self] index in
            self?.currentPage = index
            self?.pagingItem?.currentPage = index
            self?.pagingItem?.updateView?()
        }, onCopy: { [weak self] in
            self?.onCopy()
        }, onClose: { [weak self] in
            self?.dismiss(animated: true)
        })
        model.addItemView(depositItem)

        if items.count > 1 {
            let pagingItem = PagingDotsItem(pagesCount: items.count, tag: 1, required: true)
            model.addItemView(pagingItem)
            self.pagingItem = pagingItem
        }

        let shareItem = DepositShareButtonItem(tag: 2, onTap: { [weak self] in
            self?.onShare()
        })
        model.addItemView(shareItem)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        model.hideInBackground = false
    }

    private func onCopy() {
        delegate.onCopy(index: currentPage)
    }

    private func onShare() {
        delegate.onShare(index: currentPage)
    }

}

extension DepositViewController: IDepositView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
