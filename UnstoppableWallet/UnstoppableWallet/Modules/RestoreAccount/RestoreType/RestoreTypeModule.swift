enum RestoreTypeModule {
    enum RestoreType: String, CaseIterable, Identifiable {
        case recoveryOrPrivateKey
        case cloudRestore
        case fileRestore

        var id: String {
            rawValue
        }
    }
}
