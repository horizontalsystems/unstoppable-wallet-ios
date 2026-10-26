import Chart
import SwiftUI

struct ChartIndicatorSettingsView: View {
    @StateObject private var viewModel: ChartIndicatorSettingsViewModel
    private let onApply: (ChartIndicator) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focusedField: ChartIndicatorSettingsForm.Field?

    init(form: ChartIndicatorSettingsForm, onApply: @escaping (ChartIndicator) -> Void) {
        _viewModel = .init(wrappedValue: ChartIndicatorSettingsViewModel(form: form))
        self.onApply = onApply
    }

    var body: some View {
        ThemeView {
            BottomGradientWrapper {
                ScrollView {
                    VStack(spacing: 0) {
                        ThemeText(viewModel.form.description, style: .subhead, colorStyle: .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, .margin16)
                            .padding(.bottom, .margin24)

                        if let maType = viewModel.form.maType {
                            ListSection {
                                Cell(
                                    middle: {
                                        MiddleTextIcon(text: "chart_indicators.settings.ma.type_title".localized)
                                    },
                                    right: {
                                        RightButtonText(text: maType.rawValue.uppercased(), icon: "arrow_s_down") {
                                            Coordinator.shared.present(type: .alert) { isPresented in
                                                OptionAlertView(
                                                    title: "chart_indicators.settings.ma.type_title".localized,
                                                    viewItems: MaIndicator.MaType.allCases.map {
                                                        AlertViewItem(text: $0.rawValue.uppercased(), selected: $0 == maType)
                                                    },
                                                    onSelect: { viewModel.select(maType: MaIndicator.MaType.allCases[$0]) },
                                                    isPresented: isPresented
                                                )
                                            }
                                        }
                                    }
                                )
                            }
                            .padding(.bottom, .margin24)
                        }

                        ForEach(viewModel.form.fields, id: \.self) { field in
                            fieldView(field: field)
                                .padding(.bottom, field == viewModel.form.fields.last ? 0 : .margin24)
                        }
                    }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
                }
                .onTapGesture { focusedField = nil }
            } bottomContent: {
                ThemeButton(text: "button.apply".localized) {
                    if let indicator = viewModel.apply() {
                        onApply(indicator)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(!viewModel.applyEnabled)
            }
        }
        .animation(.default, value: viewModel.visibleCautions)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    focusedField = nil
                    viewModel.reset()
                }) {
                    Image("reset")
                }
                .disabled(!viewModel.resetEnabled)
            }
        }
    }

    @ViewBuilder private func fieldView(field: ChartIndicatorSettingsForm.Field) -> some View {
        let cautionState = viewModel.cautionState(for: field)

        VStack(spacing: 0) {
            ListSectionHeader(text: viewModel.form.header(for: field))

            InputTextRow {
                InputTextView(
                    placeholder: viewModel.form.placeholder(for: field),
                    text: viewModel.binding(for: field),
                    isValidText: ChartIndicatorSettingsForm.isValid(text:)
                )
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
            }
            .modifier(CautionBorder(cautionState: .constant(cautionState)))
            .modifier(CautionPrompt(cautionState: .constant(cautionState)))
        }
    }
}
