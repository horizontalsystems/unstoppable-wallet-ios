import UIKit
import HUD

class HudHelper {
    private enum ImageType { case success, error, attention }

    private static let successImage = UIImage(named: "Hud Success Icon")
    private static let errorImage = UIImage(named: "Hud Error Icon")
    private static let attentionImage = UIImage(named: "Hud Attention Icon")

    static let instance = HudHelper()

    private func show(type: ImageType, title: String?, subtitle: String?) {
        let statusImage: UIImage?
        switch type {
        case .success: statusImage = HudHelper.successImage
        case .error: statusImage = HudHelper.errorImage?.tinted(with: .crypto_Bars_Black)
        case .attention: statusImage = HudHelper.attentionImage
        }
        guard let image = statusImage else {
            return
        }
        HUD.instance.config = cryptoConfigHud()

        let statusConfig = configStatusModel()

        let textLength = (title?.count ?? 0) + (subtitle?.count ?? 0)
        let textReadDelay = min(max(1, Double(textLength) / 10), 3)

        statusConfig.dismissTimeInterval = textReadDelay

        HUDStatusFactory.instance.config = statusConfig

        let content = HUDStatusFactory.instance.view(type: .custom(image), title: title, subtitle: subtitle)
        HUD.instance.showHUD(content, onTapHUD: { hud in
            hud.hide()
        })
    }

    public func showSuccess(title: String? = nil, subtitle: String? = nil) {
        show(type: .success, title: title, subtitle: subtitle)
    }

    public func showError(title: String? = nil, subtitle: String? = nil) {
        show(type: .error, title: title, subtitle: subtitle)
    }

    public func showAttention(title: String? = nil, subtitle: String? = nil) {
        show(type: .attention, title: title, subtitle: subtitle)
    }

    public func showSpinner(title: String? = nil, userInteractionEnabled: Bool = true) {
        var customConfig = cryptoConfigHud()
        customConfig.hapticType = nil
        customConfig.userInteractionEnabled = userInteractionEnabled

        HUD.instance.config = customConfig

        let statusConfig = configStatusModel()

        statusConfig.dismissTimeInterval = nil
        statusConfig.customShowCancelInterval = nil

        statusConfig.customProgressValue = nil
        statusConfig.customProgressColor = .crypto_Bars_Black
        statusConfig.customProgressRadius = 21
        statusConfig.customProgressLineWidth = 5

        HUDStatusFactory.instance.config = statusConfig

        let content = HUDStatusFactory.instance.view(type: .progress(.custom), title: title)
        HUD.instance.showHUD(content, onTapHUD: { hud in
            hud.hide()
        })
   }

    public func hide() {
        HUD.instance.hide()
    }

    private func cryptoConfigHud() -> HUDConfig {
        var config = HUDConfig()
        config.style = .center
        config.startAdjustSize = 0.8
        config.finishAdjustSize = 0.8
        config.preferredSize = CGSize(width: 146, height: 114)
        config.backgroundColor = UIColor.crypto_Black_Bars.withAlphaComponent(0.4)
        config.blurEffectStyle = .cryptoStyle

        return config
    }

    private func configStatusModel() -> HUDStatusModel {
        let config = HUDStatusFactory.instance.config
        config.titleLabelFont = .cryptoSubhead1
        config.titleLabelColor = .crypto_Bars_Black

        config.subtitleLabelFont = .cryptoSubhead1
        config.subtitleLabelColor = .crypto_Bars_Black

        return config
    }

}
