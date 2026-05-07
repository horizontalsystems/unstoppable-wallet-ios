struct TonConnectConfig: Identifiable {
    let parameters: TonConnectParameters
    let manifest: TonConnectManifest

    var id: String {
        parameters.clientId
    }
}
