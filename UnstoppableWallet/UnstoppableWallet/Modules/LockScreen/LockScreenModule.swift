protocol ILockScreenRouter {
    func showChart(coinCode: String, coinTitle: String)
    func dismiss()
}

protocol IChartOpener: AnyObject {
    func showChart(coinCode: String, coinTitle: String)
}
