import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject var viewModel: LanguageSettingsViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            ListSection {
                ForEach(viewModel.languages, id: \.self) { language in
                    ClickableRow(action: {
                        if viewModel.currentLanguage == language {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            viewModel.currentLanguage = language
                            UIWindow.keyWindow?.set(newRootController: MainModule.instance(presetTab: .settings))
                        }
                    }) {
                        Image(language)

                        VStack(spacing: 1) {
                            if let displayName = viewModel.displayName(language: language) {
                                Text(displayName).themeBody()
                            }
                            if let nativeDisplayName = viewModel.nativeDisplayName(language: language) {
                                Text(nativeDisplayName).themeSubhead2()
                            }
                        }

                        if viewModel.currentLanguage == language {
                            Image.checkIcon
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationBarTitle("settings.language".localized)
    }
}
