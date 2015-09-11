#!/usr/bin/swift

import Foundation

enum ExitCodes : Int32 {
    case Success = 0, Failure = 1
}


func runAgvtool( arguments arguments: [String]! ) -> (Bool, Int32) {
    let task = NSTask()
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
    let name = (Process.arguments.first! as String)

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


if Process.arguments.count <= 1 {
    showHelp()
    exit(ExitCodes.Failure.rawValue)
}

let command = Process.arguments[1]
var arguments: [String]

switch ( command.lowercaseString ) {
case "bump-build":
    arguments = ["bump", "-all"]
case "set-build":
    if Process.arguments.count >= 3 {
        let buildNumber = Process.arguments[2]
        arguments = ["new-version", "-all", buildNumber]
    } else {
        showHelp("Missing <build number> parameter.")
        exit(ExitCodes.Failure.rawValue)
    }
case "set-version":
    if Process.arguments.count >= 3 {
        let version = Process.arguments[2]
        arguments = ["new-marketing-version", version]
    } else {
        showHelp("Missing <version> parameter.")
        exit(ExitCodes.Failure.rawValue)
    }
case "print-current":
    runAgvtool( arguments: ["mvers"] )
    runAgvtool( arguments: ["vers"] )
    exit(ExitCodes.Success.rawValue)
case "help":
    showHelp()
    exit(ExitCodes.Failure.rawValue)
default:
    showHelp("Unrecognized operation specifier \"\(command)\".")
    exit(ExitCodes.Failure.rawValue)
}

let (status, exitCode) = runAgvtool( arguments: arguments)
exit(exitCode)

