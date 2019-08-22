import Foundation

class ChartRateDataConverter: IChartRateConverter {

    func convert(chartRateData: ChartRateData) -> [ChartPoint] {
        let timestampScale = chartRateData.scale * 60

        var points = [ChartPoint]()
        var timestamp = chartRateData.timestamp

        chartRateData.values.reversed().forEach { value in
            points.append(ChartPoint(timestamp: timestamp, value: value))
            timestamp = timestamp - timestampScale
        }

        return points.reversed()
    }

}
