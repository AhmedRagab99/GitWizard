//
//  ProccessService.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation
import os

struct ProcessError: Error, LocalizedError {
    private var description: String
    var errorDescription: String? {
        return description
    }

    init(description: String) {
        self.description = description
    }

    init(error: Error) {
        self.init(description: error.localizedDescription)
    }
}

// process run code
extension Process {
    struct Output: CustomStringConvertible {
        var standardOutput: String
        var standardError: String
        public var description: String {
            return "Output(standardOutput: \(standardOutput), standardError: \(standardError))"
        }
    }

    static private func output(arguments: [String], currentDirectoryURL: URL?, inputs: [String] = []) async throws -> Output {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "process")
        logger.debug("Process run: arguments: \(arguments), currentDirectoryURL: \(currentDirectoryURL?.description ?? ""), inputs: \(inputs, privacy: .public)")

        let output = try run(arguments: arguments, currentDirectoryURL: currentDirectoryURL, inputs: inputs)
        logger.debug("Process output: \(output.standardOutput + output.standardError, privacy: .public)")
        return output
    }

    static private func run(arguments: [String], currentDirectoryURL: URL?, inputs: [String] = []) throws -> Output {
        let process = Process()
        let stdOutput = Pipe()
        let stdError = Pipe()
        let stdInput = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL
        process.standardOutput = stdOutput
        process.standardError = stdError
        process.standardInput = stdInput

        try process.run()

        if !inputs.isEmpty, let writeData = inputs.joined(separator: "\n").data(using: .utf8) {
            try stdInput.fileHandleForWriting.write(contentsOf: writeData)
            try stdInput.fileHandleForWriting.close()
        }

        let stdOut = String(data: stdOutput.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let errOut = String(data: stdError.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)

        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let errorMessageWhen = "An error occurred while executing the \"" + arguments.joined(separator: " ") + "\"\n\n"
            throw ProcessError(
                description: errorMessageWhen + (stdOut ?? "") + "\n" + (errOut ?? "")
            )
        }
        return .init(standardOutput: stdOut ?? "", standardError: errOut ?? "")
    }

    static func output<G: Git>(_ git: G) async throws -> G.OutputModel {
        let output = try await Self.output(arguments: git.arguments, currentDirectoryURL: git.directory)
        return try git.parse(for: output.standardOutput)
    }

    static func output<G: InteractiveGit>(_ git: G) async throws -> G.OutputModel {
        let output = try await Self.output(arguments: git.arguments, currentDirectoryURL: git.directory, inputs: git.inputs)
        return try git.parse(for: output.standardOutput)
    }
}


