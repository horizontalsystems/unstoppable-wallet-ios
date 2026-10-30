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
                    ThemeButton(text: "send.unselect_all".localized, mode: .transparent, size: .small) {
                        viewModel.unselectAll()
                    }
                    .disabled(viewModel.selectedSet.isEmpty)

                    Spacer()

                    ThemeButton(text: "send.select_all".localized, mode: .transparent, size: .small) {
                        viewModel.selectAll()
                    }
                    .disabled(viewModel.allSelected)
                }
                .padding(.top, .margin12)
                .padding(.bottom, CGFloat(43))
            }
        }
        .navigationTitle("send.unspent_outputs".localized)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.resetEnabled)
    }

    func output(viewItem: OutputSelectorViewModel2.OutputViewItem) -> some View {
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
