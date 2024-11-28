struct TonConnectParameters {
    let version: Version
    let clientId: String
    let requestPayload: TonConnectRequestPayload
    let returnDeepLink: String?

    init(version: Version, clientId: String, requestPayload: TonConnectRequestPayload, ret: String? = nil) {
        self.version = version
        self.clientId = clientId
        self.requestPayload = requestPayload
        self.returnDeepLink = ret
    }
}

extension TonConnectParameters {
    enum Version: String {
        case v2 = "2"
    }
}
