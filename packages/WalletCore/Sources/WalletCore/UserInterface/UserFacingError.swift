import Foundation

/// Marks an error whose `errorDescription` (and `failureReason`) is **safe to render to a user
/// verbatim**.
///
/// Plain `LocalizedError` conformance is not a safety signal in this codebase: several networking
/// and toolkit types adopt it purely so debug logging reads well. `HsToolKit`'s
/// `NetworkManager.ResponseError`, for instance, returns `"[statusCode: …]\n<server response body>"`
/// — showing that on a confirmation screen leaks raw server text to the user.
///
/// So UI that displays an error's own text must gate on `UserFacingError`, not on `LocalizedError`,
/// and fall back to generic copy for everything else.
///
/// Conform **only** deliberately authored, reviewed error taxonomies whose every case returns a
/// localized, human-written string built from values you control. Never conform a type that can
/// interpolate a server response, a URL, a host, a header or an underlying error's description.
public protocol UserFacingError: LocalizedError {}
