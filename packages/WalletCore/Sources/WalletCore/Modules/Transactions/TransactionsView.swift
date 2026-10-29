import SwiftUI

struct TransactionsView: View {
    @ObservedObject var viewModel: TransactionsViewModel
    let statPage: StatPage

    var body: some View {
        ForEach(viewModel.sections) { section in
            Section {
                ListForEach(section.viewItems) { viewItem in
                    ItemView(viewItem: viewItem) {
                        if let record = viewModel.record(id: viewItem.id) {
                            TransactionInfoModule.present(transactionRecord: record)
                            stat(page: statPage, event: .open(page: .transactionInfo))
                        }
                    }
                    .onAppear {
                        viewModel.onDisplay(section: section, viewItem: viewItem)
                    }
                }
            } header: {
                ThemeListSectionHeader(text: section.title)
            }
        }
    }

    struct ItemView: View, Equatable {
        let viewItem: TransactionsViewModel.ViewItem
        let action: () -> Void

        var body: some View {
            Cell(
                left: { iconView(viewItem: viewItem).opacity(viewItem.spam ? 0.25 : 1) },
                middle: {
                    VStack(spacing: 1) {
                        HStack(spacing: .margin8) {
                            ThemeText(viewItem.title, style: .headline2)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let primaryValue = viewItem.primaryValue, !primaryValue.text.isEmpty {
                                ThemeText(primaryValue.text, style: .headline2, colorStyle: colorStyle(valueType: primaryValue.type))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            if viewItem.doubleSpend || viewItem.sentToSelf || viewItem.locked != nil {
                                HStack(spacing: .margin6) {
                                    if viewItem.doubleSpend {
                                        ThemeImage("double_send", size: .iconSize20)
                                    }

                                    if viewItem.sentToSelf {
                                        ThemeImage("arrow_return", size: .iconSize20)
                                    }

                                    if let locked = viewItem.locked {
                                        Image.lock(unlocked: !locked, size: .iconSize20)
                                    }
                                }
                            }
                        }

                        HStack(spacing: .margin8) {
                            ThemeText(viewItem.subTitle, style: .subhead)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            if let secondaryValue = viewItem.secondaryValue, !secondaryValue.text.isEmpty {
                                ThemeText(secondaryValue.text, style: .subhead, colorStyle: colorStyle(valueType: secondaryValue.type))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(viewItem.spam ? 0.25 : 1)
                },
                action: action
            )
        }

        @ViewBuilder private func iconView(viewItem: TransactionsViewModel.ViewItem) -> some View {
            ZStack {
                if let progress = viewItem.progress {
                    ProgressView(value: max(0.1, progress))
                        .progressViewStyle(DeterminiteSpinnerStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    ThemeImage("warning", size: .iconSize20, colorStyle: .red)
                }
            }
            .frame(width: 44, height: 44)
        }

        private func colorStyle(valueType: TransactionsViewModel.ValueType) -> ColorStyle {
            switch valueType {
            case .incoming: return .green
            case .outgoing, .neutral: return .primary
            case .secondary: return .secondary
            }
        }

        static func == (lhs: ItemView, rhs: ItemView) -> Bool {
            lhs.viewItem == rhs.viewItem
        }
    }
}
