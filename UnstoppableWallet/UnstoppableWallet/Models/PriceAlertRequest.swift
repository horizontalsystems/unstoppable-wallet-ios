struct PriceAlertRequest {
    let topic: String
    let method: Method

    enum Method: String {
        case subscribe = "pns/subscribe"
        case unsubscribe = "pns/unsubscribe"
    }

    static func requests(topics: Set<String>, method: Method) -> [PriceAlertRequest] {
        topics.map { PriceAlertRequest(topic: $0, method: method) }
    }

}
