import UIKit

class ManageCoinsViewController: UIViewController {

    let delegate: IManageCoinsViewDelegate

    init(delegate: IManageCoinsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension ManageCoinsViewController: IManageCoinsView {

    func showCoins(enabled: [Coin], disabled: [Coin]) {

    }

    func show(error: String) {

    }

}
