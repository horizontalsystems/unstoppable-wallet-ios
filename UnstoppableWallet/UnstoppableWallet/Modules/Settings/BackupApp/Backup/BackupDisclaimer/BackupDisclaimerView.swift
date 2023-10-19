import SDWebImageSwiftUI
import SwiftUI
import ThemeKit

struct BackupDisclaimerView: View {
    @ObservedObject var viewModel: BackupAppViewModel
    var onDismiss: (() -> Void)?

    @State var isOn: Bool = false

    var body: some View {
        let backupDisclaimer = (viewModel.destination ?? .local).backupDisclaimer

        ThemeView {
            BottomGradientWrapper {
                VStack(spacing: .margin32) {
                    HighlightedTextView(text: backupDisclaimer.highlightedDescription, style: .warning)
                    ListSection {
                        ClickableRow(action: {
                            isOn.toggle()
                        }) {
                            Toggle(isOn: $isOn) {}
                                .labelsHidden()
                                .toggleStyle(CheckboxStyle())

                            Text(backupDisclaimer.selectedCheckboxText).themeSubhead2(color: .themeLeah)
                        }
                    }
                }
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
            } bottomContent: {
                NavigationLink(
                    destination: BackupNameView(viewModel: viewModel, onDismiss: onDismiss),
                    isActive: $viewModel.namePushed
                ) {
                    Button(action: { viewModel.namePushed = true }) {
                        Text("button.next".localized)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .disabled(!isOn)
            }
        }
        .navigationBarTitle(backupDisclaimer.title)

        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    onDismiss?()
                }
            }
        }
    }
}
