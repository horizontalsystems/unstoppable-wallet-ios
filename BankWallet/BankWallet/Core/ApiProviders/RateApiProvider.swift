import RxSwift

class RateApiProvider {
    private let networkManager: NetworkManager
    private let appConfigProvider: IAppConfigProvider

    private let ipfsDayFormatter = DateFormatter()
    private let ipfsHourFormatter = DateFormatter()
    private let ipfsMinuteFormatter = DateFormatter()

    init(networkManager: NetworkManager, appConfigProvider: IAppConfigProvider) {
        self.networkManager = networkManager
        self.appConfigProvider = appConfigProvider

        ipfsHourFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsHourFormatter.dateFormat = "yyyy/MM/dd/HH"

        ipfsDayFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsDayFormatter.dateFormat = "yyyy/MM/dd"

        ipfsMinuteFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsMinuteFormatter.dateFormat = "mm"
    }

}

extension RateApiProvider: IRateApiProvider {

    func getLatestRateData(currencyCode: String) -> Single<LatestRateData> {
        let urlString = "\(appConfigProvider.apiUrl)/xrates/latest/\(currencyCode)/index.json"
        return networkManager.single(urlString: urlString, httpMethod: .get)
    }

    func getRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal?> {
        let dayPath = ipfsDayFormatter.string(from: date)
        let hourPath = ipfsHourFormatter.string(from: date)
        let minuteString = ipfsMinuteFormatter.string(from: date)

        let hourUrlString = "\(appConfigProvider.apiUrl)/xrates/historical/\(coinCode)/\(currencyCode)/\(hourPath)/index.json"
        let dayUrlString = "\(appConfigProvider.apiUrl)/xrates/historical/\(coinCode)/\(currencyCode)/\(dayPath)/index.json"

        let hourSingle: Single<[String: String]> = networkManager.single(urlString: hourUrlString, httpMethod: .get)
        let daySingle: Single<String> = networkManager.single(urlString: dayUrlString, httpMethod: .get)

        return hourSingle.flatMap { rates -> Single<Decimal?> in
            if let rate = rates[minuteString], let decimal = Decimal(string: rate) {
                return Single.just(decimal)
            }

            return daySingle.map { rate -> Decimal? in
                return Decimal(string: rate)
            }
        }
    }

}
