import Foundation

/// Validates layout indices against a layout list count.
public struct LayoutValidator {
    public init() {}

    /// Validates that `index` is a valid position within a layout list of size `layoutCount`.
    ///
    /// - Throws: `ValidationError.layoutIndexOutOfBounds` if the index or count is invalid.
    /// - Returns: The original index when valid.
    @discardableResult
    public func validateLayoutIndex(_ index: Int, withinLayoutCount layoutCount: Int) throws -> Int {
        guard layoutCount > 0 else {
            throw ValidationError.layoutIndexOutOfBounds(index: index, count: layoutCount)
        }
        guard index >= 0 && index < layoutCount else {
            throw ValidationError.layoutIndexOutOfBounds(index: index, count: layoutCount)
        }
        return index
    }

    /// Returns `index` if valid, otherwise returns the default index `0`.
    ///
    /// A safe, non-throwing variant for call sites that want a fallback.
    public func safeLayoutIndex(_ index: Int, withinLayoutCount layoutCount: Int) -> Int {
        (try? validateLayoutIndex(index, withinLayoutCount: layoutCount)) ?? 0
    }
}
