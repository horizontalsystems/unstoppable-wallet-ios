import UIKit

class SyncModeViewController: WalletViewController {
    private let delegate: ISyncModeViewDelegate

    private var isFast = true

    init(delegate: ISyncModeViewDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton()
        button.setTitle("fast", for: .normal)
        button.frame = CGRect(x: 50, y: 50, width: 100, height: 50)
        view.addSubview(button)
        button.addTarget(self, action: #selector(onTapFastSync), for: .touchUpInside)

        let button2 = UIButton()
        button2.setTitle("slow", for: .normal)
        button2.frame = CGRect(x: 50, y: 150, width: 100, height: 50)
        view.addSubview(button2)
        button2.addTarget(self, action: #selector(onTapSlowSync), for: .touchUpInside)

    }

    @objc func onTapFastSync() {
        delegate.onSelectFast()
        delegate.onDone()
    }

    @objc func onTapSlowSync() {
        delegate.onSelectSlow()
        delegate.onDone()
    }

}

extension SyncModeViewController: ISyncModeView {

    func showInvalidWordsError() {
        HudHelper.instance.showError(title: "restore.validation_failed".localized)
    }

}
