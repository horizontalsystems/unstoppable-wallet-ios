import SwiftUI

struct TransactionsView: View {
    @ObservedObject var viewModel: TransactionsViewModelNew
    @Binding var presentedTransactionRecord: TransactionRecord?

    var body: some View {
        ForEach(viewModel.sections) { section in
            Section {
                ForEach(section.viewItems) { viewItem in
                    VStack(spacing: 0) {
                        if section.viewItems.first?.id == viewItem.id {
                            HorizontalDivider()
                        }

                        ItemView(viewItem: viewItem) {
                            // viewModel.onTap(section: section, viewItem: viewItem)
                            presentedTransactionRecord = viewModel.record(id: viewItem.id)
                        }
                        .onAppear {
                            viewModel.onDisplay(section: section, viewItem: viewItem)
                        }

                        HorizontalDivider()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
            } header: {
                Text(section.title)
                    .themeSubhead1(alignment: .leading)
                    .textCase(.uppercase)
                    .padding(.horizontal, .margin32)
                    .padding(.top, .margin24)
                    .padding(.bottom, .margin12)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .background(Color.themeTyler)
            }
        }
    }

    struct ItemView: View, Equatable {
        let viewItem: TransactionsViewModelNew.ViewItem
        let action: () -> Void

        var body: some View {
            ClickableRow(padding: EdgeInsets(top: .margin12, leading: 10, bottom: .margin12, trailing: .margin16), action: action) {
                HStack(spacing: 10) {
                    iconView(viewItem: viewItem)

                    VStack(spacing: 1) {
                        HStack(spacing: .margin8) {
                            Text(viewItem.title)
                                .textBody()
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let primaryValue = viewItem.primaryValue, !primaryValue.text.isEmpty {
                                Text(primaryValue.text)
                                    .textBody(color: color(valueType: primaryValue.type))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            if viewItem.doubleSpend || viewItem.sentToSelf || viewItem.locked != nil {
                                HStack(spacing: .margin6) {
                                    if viewItem.doubleSpend {
                                        Image("double_send_20").themeIcon()
                                    }

                                    if viewItem.sentToSelf {
                                        Image("arrow_return_20").themeIcon()
                                    }

                                    if let locked = viewItem.locked {
                                        Image(locked ? "lock_20" : "unlock_20").themeIcon()
                                    }
                                }
                            }
                        }

                        HStack(spacing: .margin8) {
                            Text(viewItem.subTitle)
                                .textSubhead2()
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let secondaryValue = viewItem.secondaryValue, !secondaryValue.text.isEmpty {
                                Text(secondaryValue.text)
                                    .textSubhead2(color: color(valueType: secondaryValue.type))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
                .opacity(viewItem.spam ? 0.25 : 1)
            }
        }

        @ViewBuilder private func iconView(viewItem: TransactionsViewModelNew.ViewItem) -> some View {
            ZStack {
                if let progress = viewItem.progress {
                    ProgressView(value: max(0.2, progress))
                        .progressViewStyle(DeterminiteSpinnerStyle())
                        .frame(width: 44, height: 44, alignment: .center)
                        .spinning()
                }

                switch viewItem.iconType {
                case let .icon(url, alternativeUrl, placeholderImageName, type):
                    IconView(url: url, alternativeUrl: alternativeUrl, placeholderImage: placeholderImageName, type: type)
                case let .localIcon(imageName):
                    if let imageName {
                        Image(imageName).themeIcon(color: .themeLeah)
                    }
                case let .doubleIcon(frontType, frontUrl, frontAlternativeUrl, frontPlaceholder, backType, backUrl, backAlternativeUrl, backPlaceholder):
                    ZStack {
                        VStack {
                            HStack {
                                IconView(url: backUrl, alternativeUrl: backAlternativeUrl, placeholderImage: backPlaceholder, type: backType, size: .iconSize24)
                                Spacer()
                            }
                            Spacer()
                        }

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle().fill(Color.themeTyler).frame(width: .iconSize24, height: .iconSize24)
                            }
                            .padding(.trailing, 1)
                        }
                        .padding(.bottom, 1)

                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                IconView(url: frontUrl, alternativeUrl: frontAlternativeUrl, placeholderImage: frontPlaceholder, type: frontType, size: .iconSize24)
                            }
                        }
                    }
                    .frame(width: .iconSize32, height: 36)
                case .failedIcon:
                    Image("warning_2_20")
                        .themeIcon(color: .themeLucian)
                }
            }
            .frame(width: 44)
        }

        private func color(valueType: TransactionsViewModelNew.ValueType) -> Color {
            switch valueType {
            case .incoming: return .themeRemus
            case .outgoing, .neutral: return .themeLeah
            case .secondary: return .themeGray
            }
        }

        static func == (lhs: ItemView, rhs: ItemView) -> Bool {
            lhs.viewItem == rhs.viewItem
        }
    }
}
