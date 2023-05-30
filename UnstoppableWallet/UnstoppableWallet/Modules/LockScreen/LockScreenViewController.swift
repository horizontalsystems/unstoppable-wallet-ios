import UIKit
import ThemeKit

class LockScreenViewController: ThemeViewController {
    private let unlockViewController: UIViewController

    init(unlockViewController: UIViewController) {
        self.unlockViewController = unlockViewController

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(unlockViewController)
        view.addSubview(unlockViewController.view)
        unlockViewController.didMove(toParent: self)
    }

}
