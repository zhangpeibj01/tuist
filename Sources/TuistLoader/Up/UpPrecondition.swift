import Foundation
import TSCBasic
import TuistSupport

/// Precondition required to succeed setup.
class UpPrecondition: UpRequired, GraphInitiatable {
    /// Advice to give the user if the condition isn’t met.
    let advice: String

    /// Shell command that should return a 0 exit status if the condition is met.
    let isMet: [String]

    /// Initializes a Precondition command.
    ///
    /// - Parameters:
    ///   - name: Name of the command.
    ///   - advice: Output shown to the user if this condition is not met.
    ///   - isMet: Shell command that should return a 0 exit status if the setup has already been done.
    init(name: String,
         advice: String,
         isMet: [String])
    {
        self.advice = advice
        self.isMet = isMet
        super.init(name: name)
    }

    /// Default constructor of entities that are part of the manifest.
    ///
    /// - Parameters:
    ///   - dictionary: Dictionary with the object representation.
    ///   - projectPath: Absolute path to the folder that contains the manifest.
    ///     This is useful to obtain absolute paths from the relative paths provided in the manifest by the user.
    /// - Throws: A decoding error if an expected property is missing or has an invalid value.
    required init(dictionary: JSON, projectPath _: AbsolutePath) throws {
        isMet = try dictionary.get("is_met")
        advice = try dictionary.get("advice")
        super.init(name: try dictionary.get("name"))
    }

    /// When the command is not met, this method runs it.
    ///
    /// - Parameters:
    ///   - projectPath: Path to the directory that contains the project manifest.
    /// - Throws: The advice string.
    override func meet(projectPath _: AbsolutePath) throws {
        throw CheckRequirementError.unfulfilled(advice)
    }

    /// Returns true when the precondition is met.
    ///
    /// - Parameters
    ///   - projectPath: Path to the directory that contains the project manifest.
    /// - Returns: True if the command doesn't need to be run.
    /// - Throws: An error if the check fails.
    override func isMet(projectPath: AbsolutePath) throws -> Bool {
        var launchPath: AbsolutePath!
        do {
            launchPath = try self.launchPath(command: isMet, projectPath: projectPath)
        } catch {
            return false
        }
        var arguments = [launchPath.pathString]
        arguments.append(contentsOf: Array(isMet.dropFirst()))

        do {
            try System.shared.run(arguments)
            return true
        } catch {
            return false
        }
    }

    /// Given the command components, it returns the launch path.
    /// If the launch path is a name, it uses which to find the tool directory.
    /// If it's a path, it returns the absolute path.
    ///
    /// - Parameters:
    ///   - command: Command whose launch path will be returned.
    ///   - projectPath: Project path used to get the absolute path if the command path is relative.
    /// - Returns: Launch path.
    /// - Throws: A system error if the path can't be obtained running which in the system.
    private func launchPath(command: [String], projectPath: AbsolutePath) throws -> AbsolutePath {
        // It's safe to unwrap the first argument here.
        // There's a linter in place that prevents this code from running if the command is empty.
        let launchArgument = command.first!
        if launchArgument.contains("/") {
            return AbsolutePath(launchArgument, relativeTo: projectPath)
        } else {
            return try AbsolutePath(System.shared.which(launchArgument))
        }
    }
}