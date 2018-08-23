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

}
