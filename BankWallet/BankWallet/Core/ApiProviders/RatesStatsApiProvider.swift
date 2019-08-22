import RxSwift

class RatesStatsApiProvider {
    private let networkManager: NetworkManager
    private let ipfsApiProvider: IIpfsApiProvider

    init(networkManager: NetworkManager, ipfsApiProvider: IIpfsApiProvider) {
        self.networkManager = networkManager
        self.ipfsApiProvider = ipfsApiProvider
    }

    private func getRateStatistic(baseUrlString: String, timeoutInterval: TimeInterval, coinCode: String, currencyCode: String, chartType: ChartType) -> Single<ChartRateData> {
        let urlString = "\(baseUrlString)/xrates/stats/\(currencyCode)/\(coinCode)/\(chartType.rawValue).json"

        let urlSingle: Single<ChartRateData> = networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)

        return urlSingle
    }

    private func getMarketCap(baseUrlString: String, timeoutInterval: TimeInterval) -> Single<MarketCapData> {
        let urlString = "\(baseUrlString)/xrates/stats/coininfo.json"

        let urlSingle: Single<MarketCapData> = networkManager.single(urlString: urlString, httpMethod: .get, timoutInterval: timeoutInterval)

        return urlSingle
    }

}

extension RatesStatsApiProvider: IRatesStatsApiProvider {

    func getChartRateData(coinCode: String, currencyCode: String, chartType: ChartType) -> Single<ChartRateData> {
        return ipfsApiProvider.gatewaysSingle { [unowned self] baseUrlString, timeoutInterval in
            return self.getRateStatistic(baseUrlString: baseUrlString, timeoutInterval: timeoutInterval, coinCode: coinCode, currencyCode: currencyCode, chartType: chartType)
        }
    }

    func getMarketCapData() -> Single<MarketCapData> {
        return ipfsApiProvider.gatewaysSingle { [unowned self] baseUrlString, timeoutInterval in
            return self.getMarketCap(baseUrlString: baseUrlString, timeoutInterval: timeoutInterval)
        }
    }

}
