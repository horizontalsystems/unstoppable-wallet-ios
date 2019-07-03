import UIKit
import ActionSheet

class RestoreNavigationController: WalletNavigationController {
    let viewDelegate: IRestoreViewDelegate

    init(viewDelegate: IRestoreViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewDelegate.viewDidLoad()
    }

}

extension RestoreNavigationController: IRestoreView {

    func showSelectType(types: [PredefinedAccountType]) {
        pushViewController(RestoreSelectTypeViewController(delegate: viewDelegate, types: types), animated: true)
    }

    func showWords(defaultWords: [String]) {
        pushViewController(RestoreWordsViewController(delegate: viewDelegate, defaultWords: defaultWords), animated: true)
    }

    func showSyncMode() {
        pushViewController(RestoreSyncModeViewController(delegate: viewDelegate), animated: true)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
