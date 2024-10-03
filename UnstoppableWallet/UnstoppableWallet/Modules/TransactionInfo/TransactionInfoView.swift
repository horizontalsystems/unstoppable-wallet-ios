import MarketKit
import SwiftUI

struct TransactionInfoView: View {
    @StateObject private var viewModel: TransactionInfoViewModelNew
    @Environment(\.presentationMode) private var presentationMode

    init(record: TransactionRecord, adapter: ITransactionsAdapter) {
        _viewModel = StateObject(wrappedValue: TransactionInfoViewModelNew(record: record, adapter: adapter))
    }

    var body: some View {
        ThemeNavigationView {
            ThemeView {
                ScrollView {
                    VStack(spacing: .margin16) {
                        ForEach(viewModel.sections.indices, id: \.self) { sectionIndex in
                            let section = viewModel.sections[sectionIndex]

                            ListSection {
                                ForEach(section.fields.indices, id: \.self) { index in
                                    section.fields[index].listRow
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
            }
            .navigationTitle("tx_info.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button.close".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
