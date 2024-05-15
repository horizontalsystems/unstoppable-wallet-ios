import SwiftUI

struct OutputSelectorView2: View {
    @StateObject var viewModel: OutputSelectorViewModel2

    @Environment(\.presentationMode) private var presentationMode

    init(handler: BitcoinPreSendHandler) {
        _viewModel = StateObject(wrappedValue: OutputSelectorViewModel2(handler: handler))
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: 0) {
                ListSection {
                    ListRow(minHeight: .heightDoubleLineCell) {
                        HStack(spacing: .margin8) {
                            VStack(spacing: 1) {
                                Text("send.available_balance".localized).themeSubhead2(color: .themeGray)
                            }

                            Spacer()

                            VStack(spacing: 1) {
                                Text(viewModel.availableBalanceCoinValue).themeSubhead1(color: .themeLeah, alignment: .trailing)
                                if let subtitle = viewModel.availableBalanceFiatValue {
                                    Text(subtitle).themeSubhead2(alignment: .trailing)
                                }
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))

                ListSection {
                    ListRow {
                        HStack(spacing: 0) {
                            Button(action: {
                                viewModel.selectUnselectAll()
                            }) {
                                Text(viewModel.allSelected ? "send.unselect_all".localized : "send.select_all".localized)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        Spacer()
                    }

                    ForEach(viewModel.outputsViewItems) { viewItem in
                        output(viewItem: viewItem)
                    }
                }
                .themeListStyle(.transparent)
            }
            .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin32, trailing: 0))
        }
        .navigationTitle("send.unspent_outputs".localized)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(viewModel.resetEnabled)
    }

    @ViewBuilder func output(viewItem: OutputSelectorViewModel2.OutputViewItem) -> some View {
        ClickableRow(action: {
            viewModel.toggle(viewItem: viewItem)
        }) {
            HStack(spacing: .margin16) {
                Image("check_2_20")
                    .themeIcon(color: .themeJacob)
                    .opacity(viewModel.selectedSet.contains(viewItem.id) ? 1 : 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                            .stroke(Color.themeGray, lineWidth: .heightOneDp + .heightOnePixel)
                    )

                VStack(spacing: 1) {
                    Text(viewItem.date).themeBody()
                    Text(viewItem.address).themeSubhead2()
                }
                Spacer()

                VStack(spacing: 1) {
                    Text(viewItem.coinValue).themeBody(alignment: .trailing)
                    if let subtitle = viewItem.fiatValue {
                        Text(subtitle).themeSubhead2(alignment: .trailing)
                    }
                }
            }
        }
    }
}
