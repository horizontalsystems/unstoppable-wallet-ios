import Foundation

class ChartRateDataConverter: IChartRateConverter {

    func convert(chartRateData: ChartRateData) -> [ChartPointPosition] {
        let timestampScale = chartRateData.scale * 60

        var points = [ChartPointPosition]()
        var timestamp = chartRateData.timestamp

        chartRateData.values.reversed().forEach { value in
            points.append(ChartPointPosition(timestamp: timestamp, value: value))
            timestamp = timestamp - timestampScale
        }

        return points.reversed()
    }

}
