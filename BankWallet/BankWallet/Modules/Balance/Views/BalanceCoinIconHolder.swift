import UIKit
import ThemeKit
import HUD

class BalanceCoinIconHolder: GrayIconHolder {
    private let syncSpinner = HUDProgressView(
            progress: 0,
            strokeLineWidth: 2,
            radius: 15,
            strokeColor: .themeGray,
            duration: 2
    )
    private let failedImageView = UIImageView()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        addSubview(failedImageView)
        failedImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        failedImageView.image = UIImage(named: "Attention Icon")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(coinIcon: UIImage?, spinnerProgress: Int?, failViewVisible: Bool) {
        super.bind(image: coinIcon)

        if let spinnerProgress = spinnerProgress {
            syncSpinner.set(progress: Float(spinnerProgress) / 100)
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        } else {
            syncSpinner.isHidden = true
            syncSpinner.stopAnimating()
        }

        failedImageView.isHidden = !failViewVisible
    }

}
