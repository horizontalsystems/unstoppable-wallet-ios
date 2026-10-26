import SwiftUI

struct ChartIndicatorsView: View {
    @StateObject private var viewModel: ChartIndicatorsViewModel
    @Binding private var isPresented: Bool

    @State private var settingsForm: ChartIndicatorSettingsForm?

    init(repository: IChartIndicatorsRepository, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: ChartIndicatorsViewModel(repository: repository))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                VStack(spacing: .margin24) {
                    ForEach(viewModel.sections) { section in
                        VStack(spacing: 0) {
                            ListSectionHeader(text: section.title)

                            ListSection {
                                ForEach(section.items) { item in
                                    row(item: item)
                                }
                            }
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            }
            .navigationDestination(isPresented: Binding(
                get: { settingsForm != nil },
                set: { if !$0 { settingsForm = nil } }
            )) {
                if let settingsForm {
                    ChartIndicatorSettingsView(form: settingsForm) { indicator in
                        viewModel.update(indicator: indicator)
                    }
                }
            }
            .navigationTitle("chart_indicators.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.save()
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
        .onDisappear {
            viewModel.save()
        }
    }

    @ViewBuilder private func row(item: ChartIndicatorsViewModel.Item) -> some View {
        Cell(
            left: {
                if let color = item.color {
                    Image("chart")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: .iconSize24, height: .iconSize24)
                        .foregroundColor(color)
                }
            },
            middle: {
                ThemeText(item.name, style: .body)
            },
            right: {
                HStack(spacing: .margin8) {
                    IconButton(icon: "pen", style: .secondary, mode: .transparent, size: .small) {
                        settingsForm = viewModel.form(id: item.indicatorId, index: item.index)
                    }

                    ThemeToggle(
                        isOn: Binding(
                            get: { item.enabled },
                            set: { enabled in
                                viewModel.set(enabled: enabled, id: item.indicatorId, index: item.index)
                            }
                        ).animation(),
                        style: .yellow
                    )
                }
            }
        )
    }
}
