 public protocol Versioned: Sendable {
     /// Strategy Unique Identifier
     var id: String { get }

     /// Given a version number MAJOR.MINOR.PATCH, increment the:
     /// MAJOR version when you make incompatible API changes
     /// MINOR version when you add functionality in a backward compatible manner
     /// PATCH version when you make backward compatible bug fixes
     var version: (major: Int, minor: Int, patch: Int) { get }
}

public extension Versioned {
    var versionString: String {
        "\(version.major).\(version.minor).\(version.patch)"
    }
}
