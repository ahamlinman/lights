//
//  Lights.swift
//  Lights
//
//  Created by Alex Hamlin on 3/16/25.
//

import Figlet
import ArgumentParser

@main
struct FigletTool: ParsableCommand {
    @Option(help: "Specify the input")
    public var input: String
    
    public func run() throws {
        Figlet.say(self.input)
    }
}
