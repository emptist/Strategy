 public protocol Versioned: Sendable {
     /// Strategy Unique Identifier
     static var id: String { get }
     /// A string containing the name of the strategy.
     static var name: String { get }
     /// Given a version number MAJOR.MINOR.PATCH, increment the:
     /// MAJOR version when you make incompatible API changes
     /// MINOR version when you add functionality in a backward compatible manner
     /// PATCH version when you make backward compatible bug fixes
     static var version: (major: Int, minor: Int, patch: Int) { get }
}

public extension Versioned {
    static var versionString: String {
        "\(version.major).\(version.minor).\(version.patch)"
    }
}
