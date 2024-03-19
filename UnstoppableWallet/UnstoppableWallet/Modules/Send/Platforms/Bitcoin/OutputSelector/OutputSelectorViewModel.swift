import BitcoinCore
import Combine
import Foundation
import RxSwift

class OutputSelectorViewModel: ObservableObject {
    private let disposeBag = DisposeBag()

    private let adapterService: SendBitcoinAdapterService
    private let fiatService: BaseFiatService

    @Published var changeViewItem: ChangeViewItem? = nil
    @Published var outputsViewItems = [OutputViewItem]()
    @Published var selectedSet = Set<String>()

    @Published var buttonText = "button.done".localized
    @Published var doneEnabled = true
    @Published var resetEnabled = true

    init(adapterService: SendBitcoinAdapterService, fiatService: BaseFiatService) {
        self.adapterService = adapterService
        self.fiatService = fiatService

        subscribe(disposeBag, adapterService.sendInfoStateObservable) { [weak self] _ in self?.sync() }
        sync()

        resetEnabled = adapterService.customOutputs != nil
    }

    private func sync() {
        // create outputs viewItems
        let all = adapterService.unspentOutputs.sorted { output, output2 in
            if output.timestamp > output2.timestamp { return true }
            if output.timestamp == output2.timestamp, output.outputIndex < output2.outputIndex { return true }
            return false
        }

        outputsViewItems = all.map { viewItem(unspentOutput: $0) }

        var selectedOutputs = adapterService.customOutputs

        switch adapterService.sendInfoState {
        case .loading: ()
        case .failed:
            changeViewItem = nil
        case let .completed(sendInfo):
            // create change viewItem
            if let address = sendInfo.changeAddress, let value = sendInfo.changeValue {
                changeViewItem = viewItem(address: address, value: value)
            } else {
                changeViewItem = nil
            }

            selectedOutputs = sendInfo.unspentOutputs
        }

        let selectedViewItems = selectedOutputs.map { outputs in
            outputs.map { OutputViewItem.id(hash: $0.transactionHash, index: $0.outputIndex) }
        }
        selectedSet = Set(selectedViewItems ?? [])
    }

    private func viewItem(address: String, value: Decimal) -> ChangeViewItem? {
        let primaryValue = fiatService.primaryAmountInfo(amount: value)?.formattedFull
        let secondaryValue = fiatService.secondaryAmountInfo(amount: value)?.formattedFull

        return primaryValue.map { ChangeViewItem(address: address.shortened, title: $0, subtitle: secondaryValue) }
    }

    private func viewItem(unspentOutput: UnspentOutputInfo) -> OutputViewItem {
        let coinRate = pow(10, fiatService.token?.decimals ?? 0)
        let value = Decimal(unspentOutput.value) / coinRate

        let primaryValue = fiatService.primaryAmountInfo(amount: value)?.formattedFull ?? "n/a".localized
        let secondaryValue = fiatService.secondaryAmountInfo(amount: value)?.formattedFull

        return OutputViewItem(
            outputIndex: unspentOutput.outputIndex,
            transactionHash: unspentOutput.transactionHash,
            date: DateHelper.instance.formatShortDateOnly(date: Date(timeIntervalSince1970: TimeInterval(unspentOutput.timestamp))),
            address: unspentOutput.address?.shortened ?? "n/a".localized,
            primary: primaryValue,
            secondary: secondaryValue
        )
    }
}

extension OutputSelectorViewModel {
    func toggle(viewItem: OutputViewItem) {
        if selectedSet.remove(viewItem.id) == nil {
            selectedSet.insert(viewItem.id)
        }

        selectedSet.forEach { print($0) }
        adapterService.customOutputs = adapterService.unspentOutputs.filter {
            selectedSet.contains(OutputViewItem.id(hash: $0.transactionHash, index: $0.outputIndex))
        }
        resetEnabled = true
    }

    func onTapDone() {}

    func reset() {
        adapterService.customOutputs = nil
        resetEnabled = false
    }
}

extension OutputSelectorViewModel {
    struct ChangeViewItem: Equatable {
        let address: String
        let title: String
        let subtitle: String?

        static func == (lhs: ChangeViewItem, rhs: ChangeViewItem) -> Bool {
            lhs.address == rhs.address &&
                lhs.title == rhs.title &&
                lhs.subtitle == rhs.subtitle
        }
    }

    struct OutputViewItem: Hashable, Identifiable, Equatable {
        let outputIndex: Int
        let transactionHash: Data
        let date: String
        let address: String
        let primary: String
        let secondary: String?

        var id: String {
            Self.id(hash: transactionHash, index: outputIndex)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(outputIndex)
            hasher.combine(transactionHash)
        }

        static func id(hash: Data, index: Int) -> String { [hash.hs.hexString, index.description].joined(separator: "_") }
    }
}
