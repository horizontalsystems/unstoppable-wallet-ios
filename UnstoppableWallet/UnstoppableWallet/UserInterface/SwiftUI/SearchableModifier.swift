import SwiftUI

struct SearchableModifier: ViewModifier {
    @Binding var text: String
    let prompt: String

    func body(content: Content) -> some View {
        if #available(iOS 17.1, *) {
            content
                .searchable(text: $text, prompt: prompt)
                .searchPresentationToolbarBehavior(.avoidHidingContent)
        } else {
            content
                .searchable(text: $text, prompt: prompt)
        }
    }
}

extension View {
    func searchBar(text: Binding<String>, prompt: String) -> some View {
        modifier(SearchableModifier(text: text, prompt: prompt))
    }
}

// TODO: it is used in MarketView only (remove after applying new search)
struct BottomSearchBar: View {
    @Binding var text: String
    let prompt: String

    @FocusState.Binding var focused: Bool
    @State private var cancelVisible = false

    var body: some View {
        ZStack {
            HStack(spacing: .margin12) {
                HStack(spacing: .margin8) {
                    Image("search").icon()
                    TextField("", text: $text, prompt: Text(prompt)
                        .foregroundColor(.themeGray))
                        .font(.themeBody)
                        .tint(.themeInputFieldTintColor)
                        .focused($focused)

                    if !text.isEmpty {
                        IconButton(icon: "trash_filled", style: .secondary, mode: .transparent, size: .small) {
                            text = ""
                        }
                    }
                }
                .padding(.horizontal, .margin16)
                .frame(height: 48)
                .background(Color.themeBlade)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius24, style: .continuous))

                if cancelVisible {
                    IconButton(icon: "close", style: .primary, size: .small) {
                        focused = false
                        text = ""
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.2), value: cancelVisible)
        }
        .padding(EdgeInsets(top: .margin16, leading: .margin24, bottom: .margin16, trailing: .margin24))
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
        .onChange(of: focused) { focused in
            cancelVisible = focused
        }
    }
}
