import Foundation
import SwiftUI
import UIKit

enum ChartIndicatorsModule {
    static func view(repository: IChartIndicatorsRepository, fetcher: IChartPointFetcher) -> some View {
        let service = ChartIndicatorsService(repository: repository, chartPointFetcher: fetcher)
        let viewModel = ChartIndicatorsViewModel(service: service)

        return ChartIndicatorsView(viewModel: viewModel)
    }
}

struct ChartIndicatorsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let viewModel: ChartIndicatorsViewModel

    func makeUIViewController(context _: Context) -> UIViewController {
        ThemeNavigationController(rootViewController: ChartIndicatorsViewController(viewModel: viewModel))
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
