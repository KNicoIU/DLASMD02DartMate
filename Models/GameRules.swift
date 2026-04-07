//
//  GameRules.swift
//  DartMate
//
//  Created by Nicolas Kersten on 03.04.26.
//


import Foundation

/// Start-Regel als Enum (mutuell exklusiv)
enum StartRule: String, CaseIterable, Codable, Identifiable {
    case straight = "Straight"      // Keine Einschränkung
    case double = "Double"          // Double-In
    case master = "Master"          // Double OR Treble
    
    var id: String { rawValue }
}

/// End-Regel als Enum (mutuell exklusiv)
enum EndRule: String, CaseIterable, Codable, Identifiable {
    case straight = "Straight"      // Keine Einschränkung
    case double = "Double"          // Double-Out
    case master = "Master"          // Double OR Treble 
    
    var id: String { rawValue }
}

/// Spielregeln mit Enums
struct GameRules: Codable, Equatable {
    var startRule: StartRule = .straight
    var endRule: EndRule = .straight
    
    /// Beschreibung der aktiven Regeln für UI-Anzeige
    var activeRulesDescription: String {
        var rules: [String] = []
        if startRule != .straight { rules.append("\(startRule.rawValue)-In") }
        if endRule != .straight { rules.append("\(endRule.rawValue)-Out") }
        return rules.isEmpty ? "Keine speziellen Regeln" : rules.joined(separator: " • ")
    }
    
    /// Prüft ob Regel für Spielmodus relevant ist
    func isRelevant(for mode: GameMode) -> Bool {
        switch mode {
        case .threeOhOne, .fiveOhOne:
            return true
        case .cricket:
            return false
        }
    }
    
    /// Helper: Double-In aktiv?
    var isDoubleIn: Bool { startRule == .double }
    
    /// Helper: Masters-In aktiv?
    var isMastersIn: Bool { startRule == .master }
    
    /// Helper: Double-Out aktiv?
    var isDoubleOut: Bool { endRule == .double }
    
    /// Helper: Master-Out aktiv?
    var isMasterOut: Bool { endRule == .master }
}
