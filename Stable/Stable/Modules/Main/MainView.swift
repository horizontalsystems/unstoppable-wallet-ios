import SwiftUI

struct MainView: View {
    @State private var showSettings: Bool = false

    var body: some View {
        ThemeNavigationStack {
            ThemeView(style: .topGradient) {
                ScrollView {
                    VStack(spacing: 0) {
                        ThemeCard(cornerRadius: 32) {
                            Text(verbatim: "Main")
                                .frame(maxHeight: .infinity)
                        }
                        .frame(height: 150)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .toolbarBackground(Color.themeLime, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Image("seya")
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Image("seya")
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image("settings_filled")
                    }
                }
            }
        }
    }
}
