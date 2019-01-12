import UIKit
import GrouviHUD

class HudHelper {
    static let instance = HudHelper()

    public func showSuccess(title: String? = nil) {
        var customConfig = HUDConfig()
        customConfig.style = .center
        HUD.instance.config = customConfig

        HUDStatusFactory.instance.config.dismissTimeInterval = 1
        let content = HUDStatusFactory.instance.view(type: .success, title: title)
        HUD.instance.showHUD(content, onTapHUD: { hud in
            hud.hide()
        })
    }

    public func showError(title: String? = nil) {
        var customConfig = HUDConfig()
        customConfig.style = .center
        HUD.instance.config = customConfig

        HUDStatusFactory.instance.config.dismissTimeInterval = 1
        let content = HUDStatusFactory.instance.view(type: .error, title: title)
        HUD.instance.showHUD(content, onTapHUD: { hud in
            hud.hide()
        })
    }

    public func showSpinner(title: String? = nil) {
        var customConfig = HUDConfig()
        customConfig.style = .center
        customConfig.hapticType = nil

        HUD.instance.config = customConfig

        HUDStatusFactory.instance.config.dismissTimeInterval = nil
        HUDStatusFactory.instance.config.customShowCancelInterval = nil
        HUDStatusFactory.instance.config.customProgressValue = nil
        let content = HUDStatusFactory.instance.view(type: .progress(.custom), title: title)
        HUD.instance.showHUD(content)
    }

    public func hide() {
        HUD.instance.hide()
    }

}
