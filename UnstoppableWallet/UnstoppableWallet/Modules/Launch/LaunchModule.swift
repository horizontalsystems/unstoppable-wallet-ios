import UIKit

protocol ILaunchInteractor {
    var hasAccounts: Bool { get }
    var passcodeLocked: Bool { get }
    var isPinSet: Bool { get }
    var mainShownOnce: Bool { get }
}

protocol ILaunchPresenter {
    var launchMode: LaunchMode { get }
}

enum LaunchMode {
    case noPasscode
    case intro
    case unlock
    case main
}
