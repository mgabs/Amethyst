import Foundation

/// Validates numeric configuration values for Amethyst preferences.
public struct ConfigurationValidator {
    public init() {}

    /// Validates that the main pane ratio is strictly between 0.0 and 1.0.
    public func validateMainPaneRatio(_ value: CGFloat) -> ValidationError? {
        guard value > 0.0 && value < 1.0 else {
            return .configurationInvalid("mainPaneRatio must be > 0.0 and < 1.0, got \(value)")
        }
        return nil
    }

    /// Validates that the focus-follows-mouse delay is non-negative.
    public func validateFocusFollowsMouseDelay(_ value: Double) -> ValidationError? {
        guard value >= 0.0 else {
            return .configurationInvalid("focusFollowsMouseDelay must be >= 0, got \(value)")
        }
        return nil
    }

    /// Validates that the window margin size is non-negative.
    public func validateWindowMarginSize(_ value: CGFloat) -> ValidationError? {
        guard value >= 0.0 else {
            return .configurationInvalid("windowMarginSize must be >= 0, got \(value)")
        }
        return nil
    }

    /// Validates that the window gap size is non-negative.
    public func validateWindowGapSize(_ value: CGFloat) -> ValidationError? {
        guard value >= 0.0 else {
            return .configurationInvalid("windowGapSize must be >= 0, got \(value)")
        }
        return nil
    }

    /// Validates that the maximum windows per pane is at least 1.
    public func validateMaxWindowsPerPane(_ value: Int) -> ValidationError? {
        guard value >= 1 else {
            return .configurationInvalid("maxWindowsPerPane must be >= 1, got \(value)")
        }
        return nil
    }
}
