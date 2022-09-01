import UIKit
import ActionSheet

class ThemeActionSheetController: UIViewController {
    public weak var actionSheetView: ActionSheetView?
    public var onInteractiveDismiss: (() -> ())?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeLawrence
    }

    override func dismiss(animated flag: Bool, completion: (() -> ())? = nil) {
        actionSheetView?.contentWillDismissed()
        super.dismiss(animated: flag, completion: completion)
    }
}

extension InformationViewController: ActionSheetViewDelegate {

    public func didInteractiveDismissed() {
        onInteractiveDismiss?()
    }

}
