/// A blockchain family supplied to `Core` as a unit: its descriptors, and the capabilities it conforms to.
public protocol BlockchainPlugin: AnyObject {
    var id: String { get }
    var descriptors: [BlockchainDescriptor] { get }

    /// Called exactly once, from `Core.init`, on the launch thread, in registry order, before `Core.instance` is set.
    /// Must not read `Core.shared`.
    func bootstrap(context: PluginContext) throws
}
