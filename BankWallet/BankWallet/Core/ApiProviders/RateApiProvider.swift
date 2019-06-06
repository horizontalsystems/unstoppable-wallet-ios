import RxSwift

class RateApiProvider {
    private let timeoutInterval: TimeInterval = 10
    private let lastTimeoutInterval: TimeInterval = 60

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

    private func gatewaysSingle<T>(singleProvider: @escaping (String, TimeInterval) -> Single<T>) -> Single<T> {
        let gateways = appConfigProvider.ipfsGateways
        return gatewaySingle(gateways: gateways, singleProvider: singleProvider)
    }

    private func gatewaySingle<T>(gateways: [String], singleProvider: @escaping (String, TimeInterval) -> Single<T>) -> Single<T> {
        guard let gateway = gateways.first else {
            return Single.error(ApiError.allGatewaysReturnedError)
        }

        let baseUrlString = "\(gateway)/ipns/\(appConfigProvider.ipfsId)"

        let leftGateways = Array(gateways.dropFirst())

        let timeout = leftGateways.isEmpty ? lastTimeoutInterval : timeoutInterval

        return singleProvider(baseUrlString, timeout).catchError { [unowned self] _ in
            return self.gatewaySingle(gateways: leftGateways, singleProvider: singleProvider)
        }
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
            return Single.error(ApiError.noValueForHour)
        }.catchError { _ in
            return daySingle.flatMap { rate -> Single<Decimal> in
                guard let decimal = Decimal(string: rate) else {
                    return Single.error(ApiError.noValueForDay)
                }
                return Single.just(decimal)
            }
        }
    }

}

extension RateApiProvider: IRateApiProvider {

    func getLatestRateData(currencyCode: String) -> Single<LatestRateData> {
        return gatewaysSingle { [unowned self] baseUrlString, timeoutInterval in
            return self.getLatestRateData(baseUrlString: baseUrlString, timeoutInterval: timeoutInterval, currencyCode: currencyCode)
        }
    }

    func getRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal> {
        return gatewaysSingle { [unowned self] baseUrlString, timeoutInterval in
            return self.getRate(baseUrlString: baseUrlString, timeoutInterval: timeoutInterval, coinCode: coinCode, currencyCode: currencyCode, date: date)
        }
    }

}

extension RateApiProvider {

    enum ApiError: Error {
        case noValueForHour
        case noValueForDay
        case allGatewaysReturnedError
    }

}
