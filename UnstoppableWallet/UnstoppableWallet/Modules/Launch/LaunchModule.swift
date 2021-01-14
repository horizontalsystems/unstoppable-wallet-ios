import UIKit

protocol ILaunchInteractor {
    var hasAccounts: Bool { get }
    var passcodeLocked: Bool { get }
    var isPinSet: Bool { get }
    var mainShownOnce: Bool { get }
    var jailbroken: Bool { get }
}

protocol ILaunchPresenter {
    var launchMode: LaunchMode { get }
}

enum LaunchMode {
    case jailbreak
    case noPasscode
    case intro
    case unlock
    case main
}
