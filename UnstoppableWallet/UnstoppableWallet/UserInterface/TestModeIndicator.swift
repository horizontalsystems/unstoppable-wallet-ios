import UIKit
import SnapKit

class TestModeIndicator {
    private var window: UIWindow?

    init(appConfigProvider: AppConfigProvider) {
        if appConfigProvider.testMode {
            DispatchQueue.main.async {
                self.show()
            }
        }
    }

    func show() {
        window = UIWindow()
        window?.windowLevel = UIWindow.Level.statusBar + 1
        let statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        window?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: statusBarHeight + 5)
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.isHidden = false
        window?.isUserInteractionEnabled = false

        let view = UIView()
        view.layer.cornerRadius = .cornerRadius4
        view.layer.cornerCurve = .continuous
        view.backgroundColor = .red

        window?.addSubview(view)
        view.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.width.equalTo(80)
            make.bottom.centerX.equalToSuperview()
        }

        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white
        label.text = "TESTNET"

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        window?.layoutIfNeeded()
    }

}

