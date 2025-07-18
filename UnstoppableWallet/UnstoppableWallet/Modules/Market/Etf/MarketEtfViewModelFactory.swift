import MarketKit
import SwiftUI

class MarketEtfViewModelFactory: ObservableObject {
    private var viewModels: [MarketEtfFetcher.EtfCategory: MarketEtfViewModel] = [:]
    private var chartViewModels: [MarketEtfFetcher.EtfCategory: MetricChartViewModel] = [:]
    
    func getViewModel(for category: MarketEtfFetcher.EtfCategory) -> MarketEtfViewModel {
        if let existingViewModel = viewModels[category] {
            return existingViewModel
        }
        
        let newViewModel = MarketEtfViewModel(category: category)
        viewModels[category] = newViewModel
        return newViewModel
    }
    
    func getChartViewModel(for category: MarketEtfFetcher.EtfCategory) -> MetricChartViewModel {
        if let existingViewModel = chartViewModels[category] {
            return existingViewModel
        }
        
        let newViewModel = MetricChartViewModel.etfInstance(category: category)
        chartViewModels[category] = newViewModel
        return newViewModel
    }
}
