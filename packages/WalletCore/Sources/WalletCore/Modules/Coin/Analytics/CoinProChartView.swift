import Chart
import MarketKit
import SwiftUI

struct CoinProChartView: View {
    @StateObject var chartViewModel: MetricChartViewModel
    private let type: CoinProChartModule.ProChartType
    @Binding private var isPresented: Bool

    init(coin: Coin, type: CoinProChartModule.ProChartType, isPresented: Binding<Bool>) {
        _chartViewModel = StateObject(wrappedValue: MetricChartViewModel.instance(coin: coin, type: type))
        self.type = type
        _isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                Image("chart_2_24").themeIcon(color: .themeJacob)
                Text(type.title).themeHeadline2()

                Button(action: {
                    isPresented = false
                }) {
                    Image("close_3_24")
                }
            }
            .padding(.horizontal, .margin32)
            .padding(.top, .margin24)
            .padding(.bottom, .margin12)

            ChartView(viewModel: chartViewModel, configuration: type.chartConfiguration)
                .frame(maxWidth: .infinity)
                .onFirstAppear {
                    chartViewModel.start()
                }
        }
    }
}
