import UIKit
import UIExtensions
import ThemeKit
import PinKit

class BlurManager {
    private let coverView = UIView()

    private let pinKit: IPinKit
    private var shown = false

    init(pinKit: IPinKit) {
        self.pinKit = pinKit

        coverView.backgroundColor = .themeTyler

        let logoView = UIView()

        coverView.addSubview(logoView)
        logoView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        let logoImageView = UIImageView()

        logoView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview()
            maker.size.equalTo(72)
        }

        logoImageView.image = .appIcon
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.cornerRadius = .cornerRadius16
        logoImageView.clipsToBounds = true

        let logoTitleLabel = UILabel()

        logoView.addSubview(logoTitleLabel)
        logoTitleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(logoImageView.snp.bottom).offset(28)
            maker.bottom.equalToSuperview()
        }

        logoTitleLabel.numberOfLines = 0
        logoTitleLabel.textAlignment = .center
        logoTitleLabel.font = .title2
        logoTitleLabel.textColor = .themeLeah
        logoTitleLabel.text = "Unstoppable"
    }

    private func show() {
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        let frame = window?.frame ?? UIScreen.main.bounds

        coverView.alpha = 1
        coverView.frame = frame
        window?.addSubview(coverView)
        shown = true
    }

}

extension BlurManager {

    func willResignActive() {
        if !pinKit.isLocked {
            show()
        }
    }

    func didBecomeActive() {
        guard shown else {
            return
        }

        shown = false

        UIView.animate(withDuration: 0.15, animations: {
            self.coverView.alpha = 0
        }, completion: { _ in
            self.coverView.removeFromSuperview()
        })
    }

    func willEnterForeground() {
        shown = false
        coverView.removeFromSuperview()
    }

}
