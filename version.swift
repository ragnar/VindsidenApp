#!/usr/bin/swift

import Foundation

enum ExitCodes : Int32 {
    case Success = 0, Failure = 1
}


func runAgvtool( arguments: [String]! ) -> (Bool, Int32) {
    let task = Process()
    task.launchPath = "/usr/bin/agvtool"
    task.arguments = arguments
    task.launch()

    task.waitUntilExit()

    if task.terminationStatus == ExitCodes.Success.rawValue {
        return (true, task.terminationStatus)
    } else {
        return (false, task.terminationStatus)
    }
}


func showHelp( errorMessage: String = "" ) -> Void {
    let name = (CommandLine.arguments.first! as String)

    if errorMessage.isEmpty == false {
        print("\(errorMessage)")
    }

    print("\n\(name) - Convenience program to simplify setting version and bumping build numbers")
    print("\n  usage:")
    print("\t\(name) help")
    print("\t\(name) bump-build")
    print("\t\(name) set-build <build number>")
    print("\t\(name) set-version <version>")
    print("\t\(name) print-current")
    print("\n")
}


if CommandLine.arguments.count <= 1 {
    showHelp()
    exit(ExitCodes.Failure.rawValue)
}

let command = CommandLine.arguments[1]
var arguments: [String]

switch ( command.lowercased() ) {
case "bump-build":
    arguments = ["bump", "-all"]
case "set-build":
    if CommandLine.arguments.count >= 3 {
        let buildNumber = CommandLine.arguments[2]
        arguments = ["new-version", "-all", buildNumber]
    } else {
        showHelp(errorMessage: "Missing <build number> parameter.")
        exit(ExitCodes.Failure.rawValue)
    }
case "set-version":
    if CommandLine.arguments.count >= 3 {
        let version = CommandLine.arguments[2]
        arguments = ["new-marketing-version", version]
    } else {
        showHelp(errorMessage: "Missing <version> parameter.")
        exit(ExitCodes.Failure.rawValue)
    }
case "print-current":
    let _ = runAgvtool( arguments: ["mvers"] )
    let _ = runAgvtool( arguments: ["vers"] )
    exit(ExitCodes.Success.rawValue)
case "help":
    showHelp()
    exit(ExitCodes.Failure.rawValue)
default:
    showHelp(errorMessage: "Unrecognized operation specifier \"\(command)\".")
    exit(ExitCodes.Failure.rawValue)
}

let (status, exitCode) = runAgvtool( arguments: arguments)
exit(exitCode)

