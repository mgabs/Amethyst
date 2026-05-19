import Foundation

/// Errors produced by validation operations.
public enum ValidationError: LocalizedError {
    case configurationInvalid(String)
    case frameBoundsInvalid(String)
    case layoutIndexOutOfBounds(index: Int, count: Int)

    public var errorDescription: String? {
        switch self {
        case .configurationInvalid(let message):
            return "Invalid configuration: \(message)"
        case .frameBoundsInvalid(let message):
            return "Invalid frame bounds: \(message)"
        case .layoutIndexOutOfBounds(let index, let count):
            return "Layout index \(index) is out of bounds (count: \(count))"
        }
    }
}

/// Protocol for types that validate a value and return a `ValidationError` on failure.
public protocol Validator {
    associatedtype Value
    func validate(_ value: Value) -> ValidationError?
}
