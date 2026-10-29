import SwiftUI

struct OutputSelectorView2: View {
    @StateObject var viewModel: OutputSelectorViewModel2

    @Environment(\.presentationMode) private var presentationMode

    init(handler: BitcoinPreSendHandler) {
        _viewModel = StateObject(wrappedValue: OutputSelectorViewModel2(handler: handler))
    }

    var body: some View {
        ThemeView {
            VStack {
                ListSection {
                    Cell(
                        middle: { ThemeText("send.available_balance".localized, style: .subhead) },
                        right: {
                            RightMultiText(subtitleSB: viewModel.availableBalanceCoinValue, subtitle: viewModel.availableBalanceFiatValue)
                        }
                    )
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))

                ScrollView {
                    ListSection {
                        ForEach(viewModel.outputsViewItems) { viewItem in
                            output(viewItem: viewItem)
                        }
                    }
                    .themeListStyle(.transparent)
                }

                HorizontalDivider(color: .themeBlade, height: .heightOneDp)

                HStack {
                    Button(action: {
                        viewModel.unselectAll()
                    }) {
                        Text("send.unselect_all".localized).themeBody(color: viewModel.selectedSet.isEmpty ? .themeGray50 : .themeJacob)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.selectAll()
                    }) {
                        Text("send.select_all".localized).themeBody(color: viewModel.allSelected ? .themeGray50 : .themeJacob, alignment: .trailing)
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: CGFloat(43), trailing: .margin16))
            }
        }
        .navigationTitle("send.unspent_outputs".localized)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.resetEnabled)
    }

    @ViewBuilder func output(viewItem: OutputSelectorViewModel2.OutputViewItem) -> some View {
        Cell(
            left: { CheckBoxUiView(checked: .init(get: { viewModel.selectedSet.contains(viewItem.id) }, set: { _ in })) },
            middle: { MultiText(title: viewItem.date, subtitle: viewItem.address) },
            right: { RightMultiText(title: viewItem.coinValue, subtitle: viewItem.fiatValue) },
            action: {
                viewModel.toggle(viewItem: viewItem)
            }
        )
    }
}
