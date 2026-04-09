import Foundation

// Runtime verification helper for shadow migration of sort logic.
// Compares two sorted arrays element-by-element and reports mismatches via
// console print (always) and HudHelper banner (once-per-label on success,
// always on mismatch).
//
// Used during the per-module migration phases: each callsite runs both the
// legacy sort and the new criterion-based sort, then calls verify(...) with
// both results. The legacy result is still fed to the UI; the new result is
// only checked for divergence. After all callsites pass, this helper and its
// calls are deleted in the final cleanup phase.
enum SortingDiagnostics {
    private static var loggedSuccessLabels = Set<String>()

    static func verify<T>(
        label: String,
        old: [T],
        new: [T],
        isEqual: (T, T) -> Bool,
        describe: (T) -> String
    ) {
        let identical = old.count == new.count && zip(old, new).allSatisfy(isEqual)

        if identical {
            print("[Sort:\(label)] ✓ identical (\(old.count) items)")
            if !loggedSuccessLabels.contains(label) {
                loggedSuccessLabels.insert(label)
                DispatchQueue.main.async {
                    HudHelper.instance.show(banner: .success(string: "Sort \(label): ✓"))
                }
            }
            return
        }

        print("[Sort:\(label)] ✗ MISMATCH (old=\(old.count), new=\(new.count))")
        print("  --- OLD ---")
        for (i, item) in old.enumerated() {
            print("    [\(i)] \(describe(item))")
        }
        print("  --- NEW ---")
        for (i, item) in new.enumerated() {
            print("    [\(i)] \(describe(item))")
        }

        for i in 0 ..< min(old.count, new.count) where !isEqual(old[i], new[i]) {
            print("  -> first divergence at \(i):")
            print("      old: \(describe(old[i]))")
            print("      new: \(describe(new[i]))")
            break
        }

        DispatchQueue.main.async {
            HudHelper.instance.show(banner: .error(string: "Sort \(label): MISMATCH"))
        }
    }
}
