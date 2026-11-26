/// Supplies the restore-settings handlers of the plugin's blockchains.
///
/// Handler lists are constants: they are read before `bootstrap`, from an un-bootstrapped instance.
protocol RestoreSettingsCapability: BlockchainPlugin {
    var restoreSettingsHandlers: [RestoreSettingsHandler.Type] { get }
}
