import UIKit

class ThemeActionSheetController: UIViewController {
    public weak var actionSheetView: ActionSheetView?
    public var onInteractiveDismiss: (() -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeLawrence
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        actionSheetView?.contentWillDismissed()
        super.dismiss(animated: flag, completion: completion)
    }
}
