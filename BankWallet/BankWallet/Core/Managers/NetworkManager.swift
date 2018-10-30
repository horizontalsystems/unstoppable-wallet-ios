import RxSwift

class NetworkManager {

}

extension NetworkManager: IRateNetworkManager {

    func getLatestRate(coin: String, currencyCode: String) -> Observable<Double> {
        if coin == "BTCt" {
            return Observable.just(6500)
        } else if coin == "BCHt" {
            return Observable.just(500)
        }
        return Observable.just(300)
    }

    func getRate(coin: String, fiat: String, year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Observable<Double> {
        return Observable.just(6500)
    }

}
