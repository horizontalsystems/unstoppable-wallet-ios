import RxSwift

class RateApiProvider {
    private let networkManager: NetworkManager
    private let ipfsApiProvider: IIpfsApiProvider

    private let ipfsDayFormatter = DateFormatter()
    private let ipfsHourFormatter = DateFormatter()
    private let ipfsMinuteFormatter = DateFormatter()

    init(networkManager: NetworkManager, ipfsApiProvider: IIpfsApiProvider) {
        self.networkManager = networkManager
        self.ipfsApiProvider = ipfsApiProvider

        ipfsHourFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsHourFormatter.dateFormat = "yyyy/MM/dd/HH"

        ipfsDayFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsDayFormatter.dateFormat = "yyyy/MM/dd"

        ipfsMinuteFormatter.timeZone = TimeZone(abbreviation: "UTC")
        ipfsMinuteFormatter.dateFormat = "mm"
    }

    private func getLatestRateData(baseUrlString: String, timeoutInterval: TimeInterval, currencyCode: String) -> Single<LatestRateData> {
        let urlString = "\(baseUrlString)/xrates/latest/\(currencyCode)/index.json"
        return networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)
    }

    private func getRate(baseUrlString: String, timeoutInterval: TimeInterval, coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        let dayPath = ipfsDayFormatter.string(from: date)
        let hourPath = ipfsHourFormatter.string(from: date)
        let minuteString = ipfsMinuteFormatter.string(from: date)

        let hourUrlString = "\(baseUrlString)/xrates/historical/\(coinCode)/\(currencyCode)/\(hourPath)/index.json"
        let dayUrlString = "\(baseUrlString)/xrates/historical/\(coinCode)/\(currencyCode)/\(dayPath)/index.json"

        let hourSingle: Single<[String: String]> = networkManager.single(urlString: hourUrlString, httpMethod: .get, timoutInterval: timeoutInterval)
        let daySingle: Single<String> = networkManager.single(urlString: dayUrlString, httpMethod: .get, timoutInterval: timeoutInterval)

        return hourSingle.flatMap { rates -> Single<Decimal> in
            if let rate = rates[minuteString], let decimal = Decimal(string: rate) {
                return Single.just(decimal)
            }
            return Single.error(RateApiError.noValueForHour)
        }.catchError { _ in
            return daySingle.flatMap { rate -> Single<Decimal> in
                guard let decimal = Decimal(string: rate) else {
                    return Single.error(RateApiError.noValueForDay)
                }
                return Single.just(decimal)
            }
        }
    }

}

extension RateApiProvider: IRateApiProvider {

    func getLatestRateData(currencyCode: String) -> Single<LatestRateData> {
        return ipfsApiProvider.gatewaysSingle { [unowned self] baseUrlString, timeoutInterval in
            return self.getLatestRateData(baseUrlString: baseUrlString, timeoutInterval: timeoutInterval, currencyCode: currencyCode)
        }
    }

    func getRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        return ipfsApiProvider.gatewaysSingle { [unowned self] baseUrlString, timeoutInterval in
            return self.getRate(baseUrlString: baseUrlString, timeoutInterval: timeoutInterval, coinCode: coinCode, currencyCode: currencyCode, date: date)
        }
    }

}

extension RateApiProvider {

    enum RateApiError: Error {
        case noValueForHour
        case noValueForDay
        case allGatewaysReturnedError
    }

}
