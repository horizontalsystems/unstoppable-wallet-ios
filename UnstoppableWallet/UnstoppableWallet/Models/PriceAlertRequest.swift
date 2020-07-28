struct PriceAlertRequest {
    let topic: String
    let method: Method

    enum Method: String {
        case subscribe = "pns/subscribe"
        case unsubscribe = "pns/unsubscribe"
    }

}
