import UIKit
import SnapKit
import ThemeKit
import HUD
import Chart
import ComponentKit

class ChartMarketCardCell<PreviewView: ChartMarketCardView>: MarketCardCell<MarketCardView> {
    private var configuration: ChartConfiguration?
}

extension ChartMarketCardCell {

    func set(configuration: ChartConfiguration) {
        self.configuration = configuration
        marketCardViews.compactMap { $0 as? ChartMarketCardView }.forEach { view in view.set(configuration: configuration) }
    }

    func append(viewItem: ChartMarketCardView.ViewItem, onTap: (() -> ())? = nil) {
        let marketCardView = PreviewView()
        append(view: marketCardView)

        marketCardView.onTap = onTap
        if let configuration = configuration {
            marketCardView.set(configuration: configuration)
        }
        marketCardView.set(viewItem: viewItem)
    }

}
