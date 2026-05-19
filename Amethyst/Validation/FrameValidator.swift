import Foundation

/// Validates and clamps window frames against screen bounds.
public struct FrameValidator {
    public init() {}

    /// Validates that `frame` fits within `screenFrame`.
    ///
    /// - Throws: `ValidationError.frameBoundsInvalid` if any constraint is violated.
    /// - Returns: The original frame when valid.
    @discardableResult
    public func validateWindowFrame(_ frame: CGRect, withinScreen screenFrame: CGRect) throws -> CGRect {
        guard frame.size.width > 0 else {
            throw ValidationError.frameBoundsInvalid("width must be > 0, got \(frame.size.width)")
        }
        guard frame.size.height > 0 else {
            throw ValidationError.frameBoundsInvalid("height must be > 0, got \(frame.size.height)")
        }
        guard frame.origin.x >= screenFrame.origin.x else {
            throw ValidationError.frameBoundsInvalid(
                "frame.origin.x \(frame.origin.x) is less than screen.origin.x \(screenFrame.origin.x)"
            )
        }
        guard frame.origin.y >= screenFrame.origin.y else {
            throw ValidationError.frameBoundsInvalid(
                "frame.origin.y \(frame.origin.y) is less than screen.origin.y \(screenFrame.origin.y)"
            )
        }
        guard frame.maxX <= screenFrame.maxX else {
            throw ValidationError.frameBoundsInvalid(
                "frame.maxX \(frame.maxX) exceeds screen.maxX \(screenFrame.maxX)"
            )
        }
        guard frame.maxY <= screenFrame.maxY else {
            throw ValidationError.frameBoundsInvalid(
                "frame.maxY \(frame.maxY) exceeds screen.maxY \(screenFrame.maxY)"
            )
        }
        return frame
    }

    /// Clamps `frame` to fit within `screenFrame`, adjusting position and size as needed.
    ///
    /// - Returns: A frame guaranteed to fit within `screenFrame`.
    public func clampWindowFrame(_ frame: CGRect, withinScreen screenFrame: CGRect) -> CGRect {
        let clampedWidth = min(frame.width, screenFrame.width)
        let clampedHeight = min(frame.height, screenFrame.height)
        let clampedX = max(screenFrame.minX, min(frame.origin.x, screenFrame.maxX - clampedWidth))
        let clampedY = max(screenFrame.minY, min(frame.origin.y, screenFrame.maxY - clampedHeight))
        return CGRect(x: clampedX, y: clampedY, width: clampedWidth, height: clampedHeight)
    }
}
