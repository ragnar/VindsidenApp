#!/usr/bin/swift

import Foundation

enum ExitCodes : Int32 {
    case Success = 0, Failure = 1
}


func runAgvtool( #arguments: [String]! ) -> (Bool, Int32) {
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


func showHelp( _ errorMessage: String = "" ) -> Void {
    let name = (Process.arguments.first! as String).lastPathComponent

    if errorMessage.isEmpty == false {
        println("\(errorMessage)")
    }

    println("\n\(name) - Convenience program to simplify setting version and bumping build numbers")
    println("\n  usage:")
    println("\t\(name) help")
    println("\t\(name) bump-build")
    println("\t\(name) set-build <build number>")
    println("\t\(name) set-version <version>")
    println("\t\(name) print-current")
    println("\n")
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

