//
//  Logger+Extension.swift
//  Bulls'N'Bears
//
//  Created by aDev on 12/01/2024.
//

import Foundation
import OSLog

extension Logger {
    static let subsystem = Bundle.main.bundleIdentifier!
    static let errorMessage = Logger(subsystem: subsystem, category: "Error")
    static let warningMessage = Logger(subsystem: subsystem, category: "Warning")
}

