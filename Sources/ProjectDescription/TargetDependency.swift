import Foundation

/// Dependency status used by `.framework` and `.xcframework` target
/// dependencies
public enum FrameworkStatus: String, Codable, Hashable {
    /// Required dependency
    case required

    /// Optional dependency (weakly linked)
    case optional
}

/// Dependency status used by `.sdk` target dependencies
public enum SDKStatus: String, Codable, Hashable {
    /// Required dependency
    case required

    /// Optional dependency (weakly linked)
    case optional
}

/// Dependency type used by `.sdk` target dependencies
public enum SDKType: String, Codable, Hashable {
    /// Library SDK dependency
    case library

    /// Framework SDK dependency
    case framework
}

/// A target dependency.
public enum TargetDependency: Codable, Hashable {
    public enum PackageType: Codable, Hashable {
        /// A runtime package type represents a standard package whose sources are linked at runtime.
        /// For example importing the framework and consuming from dependent targets.
        case runtime

        /// A plugin package represents a package that's loaded by the build system at compile-time to
        /// extend the compilation process.
        case plugin

        /// A macro package represents a package that contains a Swift Macro.
        case macro
    }

    /// A condition applied to a `TargetDependency` allowing it to only be used in certain circumstances
    @available(*, deprecated, renamed: "PlatformCondition")
    public struct Condition: Codable, Hashable, Equatable {
        public let platformFilters: Set<PlatformFilter>
        /// For internal use only. use `.when` to ensure we can not have a `Condition` with an empty set of filters.
        private init(platformFilters: Set<PlatformFilter>) {
            self.platformFilters = platformFilters
        }

        /// Creates a condition using the specified set of filters.
        /// - Parameter platformFilters: filters to define which platforms this condition supports
        /// - Returns: a `Condition` with the given set of filters or `nil` if empty.
        public static func when(_ platformFilters: Set<PlatformFilter>) -> Condition? {
            guard !platformFilters.isEmpty else { return nil }
            return Condition(platformFilters: platformFilters)
        }
    }

    /// Dependency on another target within the same project
    ///
    /// - Parameters:
    ///   - name: Name of the target to depend on
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case target(name: String, condition: PlatformCondition? = nil)

    /// Dependency on a target within another project
    ///
    /// - Parameters:
    ///   - target: Name of the target to depend on
    ///   - path: Relative path to the other project directory
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case project(target: String, path: Path, condition: PlatformCondition? = nil)

    /// Dependency on a prebuilt framework
    ///
    /// - Parameters:
    ///   - path: Relative path to the prebuilt framework
    ///   - status: The dependency status (optional dependencies are weakly linked)
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case framework(path: Path, status: FrameworkStatus = .required, condition: PlatformCondition? = nil)

    /// Dependency on prebuilt library
    ///
    /// - Parameters:
    ///   - path: Relative path to the prebuilt library
    ///   - publicHeaders: Relative path to the library's public headers directory
    ///   - swiftModuleMap: Relative path to the library's swift module map file
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case library(path: Path, publicHeaders: Path, swiftModuleMap: Path?, condition: PlatformCondition? = nil)

    /// Dependency on a swift package manager product using Xcode native integration. It's recommended to use `external` instead.
    /// For more info, check the [external dependencies documentation](https://docs.tuist.io/guides/third-party-dependencies/).
    ///
    /// - Parameters:
    ///   - product: The name of the output product. ${PRODUCT_NAME} inside Xcode.
    ///              e.g. RxSwift
    ///   - type: The type of package being integrated.
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case package(product: String, type: PackageType = .runtime, condition: PlatformCondition? = nil)

    /// Dependency on a swift package manager plugin product using Xcode native integration.
    ///
    /// - Parameters:
    ///   - product: The name of the output product. ${PRODUCT_NAME} inside Xcode.
    ///              e.g. RxSwift
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case packagePlugin(product: String, condition: PlatformCondition? = nil)

    /// Dependency on system library or framework
    ///
    /// - Parameters:
    ///   - name: Name of the system library or framework (not including extension)
    ///            e.g. `ARKit`, `c++`
    ///   - type: The dependency type
    ///   - status: The dependency status (optional dependencies are weakly linked)
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case sdk(name: String, type: SDKType, status: SDKStatus, condition: PlatformCondition? = nil)

    /// Dependency on a xcframework
    ///
    /// - Parameters:
    ///   - path: Relative path to the xcframework
    ///   - status: The dependency status (optional dependencies are weakly linked)
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case xcframework(path: Path, status: FrameworkStatus = .required, condition: PlatformCondition? = nil)

    /// Dependency on XCTest.
    case xctest

    /// Dependency on an external dependency imported through `Dependencies.swift`.
    ///
    /// - Parameters:
    ///   - name: Name of the external dependency
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    case external(name: String, condition: PlatformCondition? = nil)

    case cocoapod(type: SDKType, content: String)

    /// Dependency on system library or framework
    ///
    /// - Parameters:
    ///   - name: Name of the system library or framework (including extension)
    ///            e.g. `ARKit.framework`, `libc++.tbd`
    ///   - type: Whether or not this dependecy is required. Defaults to `.required`
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    public static func sdk(name: String, type: SDKType, condition: PlatformCondition? = nil) -> TargetDependency {
        .sdk(name: name, type: type, status: .required, condition: condition)
    }

    /// Dependency on another target within the same project. This is just syntactic sugar for `.target(name: target.name)`.
    ///
    /// - Parameters:
    ///   - target: Instance of the target to depend on
    ///   - condition: condition under which to use this dependency, `nil` if this should always be used
    public static func target(_ target: Target, condition: PlatformCondition? = nil) -> TargetDependency {
        .target(name: target.name, condition: condition)
    }

    public var typeName: String {
        switch self {
        case .target:
            return "target"
        case .project:
            return "project"
        case .framework:
            return "framework"
        case .library:
            return "library"
        case .package:
            return "package"
        case .packagePlugin:
            return "packagePlugin"
        case .sdk:
            return "sdk"
        case .xcframework:
            return "xcframework"
        case .xctest:
            return "xctest"
        case .external:
            return "external"
        case .cocoapod:
            return "cocoapod"
        }
    }
}
