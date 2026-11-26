/// App lifecycle hooks of the plugin's kits.
///
/// - `didEnterBackground()` and `willEnterForeground()` are called on the thread `AppManager` is called on (main).
/// - `clear(exceptAccountIds:)` is called on a background queue from `KitCleaner`.
public protocol LifecycleCapability: BlockchainPlugin {
    func didEnterBackground()
    func willEnterForeground()
    func clear(exceptAccountIds: [String]) throws
}
