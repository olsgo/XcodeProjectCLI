import Foundation
import XcodeProj

final class Project {
    private(set) static var projectRoot = ""

    let targets: ProjectTargets
    let groups: ProjectGroups
    let files: ProjectFiles

    private let project: XcodeProj

    init(projectPath: String?) throws {
        var projectPath = projectPath

        if projectPath == nil, let currentDir = ProcessInfo.processInfo.environment["PWD"] {
            let contents = try FileManager.default.contentsOfDirectory(atPath: currentDir)
            projectPath = contents.first { $0.hasSuffix(".xcodeproj") }
            projectPath = InputPath(projectPath ?? "", projectRoot: currentDir).absolutePath
        }

        guard let projectPath else {
            throw CLIError.xcodeProjectNotFound
        }

        let absoluteProjectPath = Self.absoluteProjectPath(from: projectPath)
        Self.projectRoot = (absoluteProjectPath as NSString).deletingLastPathComponent

        self.project = try XcodeProj(pathString: absoluteProjectPath)
        self.targets = ProjectTargets(project: project)
        self.groups = ProjectGroups(project: project)
        self.files = ProjectFiles(project: project)
    }

    func save() throws {
        if let path = project.path {
            try project.write(path: path, override: true)
        }
    }

    private static func absoluteProjectPath(from path: String) -> String {
        let expandedPath = NSString(string: path).expandingTildeInPath

        if NSString(string: expandedPath).isAbsolutePath {
            return URL(fileURLWithPath: expandedPath).standardizedFileURL.path
        }

        let currentDir = FileManager.default.currentDirectoryPath
        let baseURL = URL(fileURLWithPath: currentDir, isDirectory: true)
        return URL(fileURLWithPath: expandedPath, relativeTo: baseURL)
            .standardizedFileURL
            .path
    }
}
