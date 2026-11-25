import SwiftUI

/// Drives the visibility of a button floating over a scroll view: visible while the content fits;
/// when it does not fit, visible only while scrolled away from the top, regardless of scroll direction.
/// `nil` means not determined yet and is shown as hidden, so the first determination never hides a drawn button.
/// The first determination waits for `isContentReady` and is made from scroll geometry laid out with that content;
/// "fits" is confirmed only once that geometry has settled, since a list sizes its rows over several layout passes.
/// Scroll geometry is observable from iOS 18 on; on iOS 17 the button resolves to visible on appear.
struct FloatingButtonVisibilityModifier: ViewModifier {
    /// How long a "content fits" geometry must stay unchanged before the button is first shown
    private static let settleDuration: Duration = .milliseconds(300)

    @Binding var isVisible: Bool?
    let isContentReady: Bool

    @State private var latestState = LatestScrollState()

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: ScrollState.self) { geometry in
                    let state = ScrollState(geometry: geometry, isContentReady: isContentReady)
                    latestState.value = state
                    return state
                } action: { _, newState in
                    update(state: newState)
                }
                // the scroll action is not called for the initial value, so a list whose geometry never changes after
                // its first layout is resolved from the container's geometry action, using the latest scroll geometry
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { _ in
                    resolveFromLatestState(retry: true)
                }
                .onChange(of: isContentReady) { _, isContentReady in
                    if isContentReady {
                        resolveFromLatestState(retry: true)
                    }
                }
                // a confirmation cancelled on disappear is started again from the stored geometry
                .onAppear {
                    resolveFromLatestState(retry: true)
                }
                .onDisappear {
                    cancelPendingConfirmation()
                }
        } else {
            content.onAppear {
                if isVisible == nil {
                    isVisible = true
                }
            }
        }
    }

    private func update(state: ScrollState) {
        guard isVisible != nil else {
            determineFirst(state: state)
            return
        }

        guard state.isLaidOut else {
            return
        }

        set(visible: state.showsButton)
    }

    /// Guaranteed first evaluation when no scroll action fires. When no usable geometry is stored yet,
    /// it tries once more after a main-actor hop, by which time the layout pass in progress has stored it.
    private func resolveFromLatestState(retry: Bool) {
        guard isVisible == nil else {
            return
        }

        if let state = latestState.value, state.isUsableForFirstDetermination {
            determineFirst(state: state)
        } else if retry {
            Task { @MainActor in
                resolveFromLatestState(retry: false)
            }
        }
    }

    /// The first determination. Every new geometry while undetermined cancels a pending confirmation.
    /// Content that does not fit resolves at once from the scroll position (hidden at the top, which changes nothing on screen).
    /// Content that fits starts a settle period; the button is shown only if no newer geometry arrived meanwhile
    /// and the latest geometry still fits, so a geometry measured before the rows settled cannot draw a button that then hides.
    private func determineFirst(state: ScrollState) {
        guard isVisible == nil else {
            return
        }

        cancelPendingConfirmation()

        guard state.isUsableForFirstDetermination else {
            return
        }

        guard state.maxOffset <= 0 else {
            set(visible: state.showsButton)
            return
        }

        latestState.pendingConfirmation = Task { @MainActor in
            try? await Task.sleep(for: Self.settleDuration)

            guard !Task.isCancelled else {
                return
            }

            latestState.pendingConfirmation = nil

            guard isVisible == nil, let latest = latestState.value, latest.isUsableForFirstDetermination else {
                return
            }

            set(visible: latest.showsButton)
        }
    }

    private func cancelPendingConfirmation() {
        latestState.pendingConfirmation?.cancel()
        latestState.pendingConfirmation = nil
    }

    private func set(visible: Bool) {
        if isVisible != visible {
            isVisible = visible
        }
    }
}

private extension FloatingButtonVisibilityModifier {
    struct ScrollState: Equatable {
        let offset: CGFloat
        let maxOffset: CGFloat
        let isLaidOut: Bool
        /// whether the transform that produced this state saw the content ready
        let isContentReady: Bool

        var isUsableForFirstDetermination: Bool {
            isLaidOut && isContentReady
        }

        /// content that fits always shows the button; content that does not fit shows it only away from the top
        var showsButton: Bool {
            maxOffset <= 0 || offset > 0
        }

        @available(iOS 18.0, *)
        init(geometry: ScrollGeometry, isContentReady: Bool) {
            let maxOffset = geometry.contentSize.height + geometry.contentInsets.top + geometry.contentInsets.bottom - geometry.containerSize.height
            let offset = min(max(geometry.contentOffset.y + geometry.contentInsets.top, 0), max(maxOffset, 0))

            self.offset = offset.rounded()
            self.maxOffset = maxOffset.rounded()
            isLaidOut = geometry.contentSize.height > 0 && geometry.containerSize.height > 0
            self.isContentReady = isContentReady
        }
    }

    /// Written by the scroll geometry transform, so the latest geometry is readable even when no scroll action fired;
    /// also holds the pending "fits" confirmation, which must survive view updates without being observed.
    /// Must stay a plain class (not `@Observable` / `ObservableObject`): the transform writes to it during layout.
    final class LatestScrollState {
        var value: ScrollState?
        var pendingConfirmation: Task<Void, Never>?
    }
}

extension View {
    func floatingButtonVisibility(_ isVisible: Binding<Bool?>, isContentReady: Bool) -> some View {
        modifier(FloatingButtonVisibilityModifier(isVisible: isVisible, isContentReady: isContentReady))
    }
}
