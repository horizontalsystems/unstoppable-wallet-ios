import RxSwift

class NetworkManager {

}

extension NetworkManager: IRateNetworkManager {

    func getLatestRate(coin: String, currencyCode: String) -> Observable<Double> {
        if coin == "BTCt" {
            return Observable.just(6593.2369)
        } else if coin == "BCHt" {
            return Observable.just(529.7463)
        }
        return Observable.just(312.3478)
    }

    func getRate(coin: String, fiat: String, year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Observable<Double> {
        return Observable.just(6500)
    }

}
