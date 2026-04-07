//
//  DartSegment.swift
//  DartMate
//
//  Created by Nicolas Kersten on 02.04.26.
//


import Foundation

enum DartSegment: String, CaseIterable, Identifiable, Codable {
    // Miss
    case miss = "Miss"
    
    // Singles 1-20
    case s1 = "S1", s2 = "S2", s3 = "S3", s4 = "S4", s5 = "S5"
    case s6 = "S6", s7 = "S7", s8 = "S8", s9 = "S9", s10 = "S10"
    case s11 = "S11", s12 = "S12", s13 = "S13", s14 = "S14", s15 = "S15"
    case s16 = "S16", s17 = "S17", s18 = "S18", s19 = "S19", s20 = "S20"
    
    // Doubles 1-20
    case d1 = "D1", d2 = "D2", d3 = "D3", d4 = "D4", d5 = "D5"
    case d6 = "D6", d7 = "D7", d8 = "D8", d9 = "D9", d10 = "D10"
    case d11 = "D11", d12 = "D12", d13 = "D13", d14 = "D14", d15 = "D15"
    case d16 = "D16", d17 = "D17", d18 = "D18", d19 = "D19", d20 = "D20"
    
    // Triples 1-20
    case t1 = "T1", t2 = "T2", t3 = "T3", t4 = "T4", t5 = "T5"
    case t6 = "T6", t7 = "T7", t8 = "T8", t9 = "T9", t10 = "T10"
    case t11 = "T11", t12 = "T12", t13 = "T13", t14 = "T14", t15 = "T15"
    case t16 = "T16", t17 = "T17", t18 = "T18", t19 = "T19", t20 = "T20"
    
    // Bulls
    case bull = "Bull"
    case bullseye = "Bullseye"
    
    var id: String { rawValue }
    
    /// Standard Dartboard-Nummernreihenfolge
    static let dartboardOrder = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
    
    /// Winkel für jede Position
    static func angle(for number: Int) -> Double {
        guard let index = dartboardOrder.firstIndex(of: number) else { return 0 }
        return Double(index) * 18.0 - 90.0 // -90° damit 20 oben ist
    }
    
    /// Berechnet die Punkte für dieses Segment
    var points: Int {
        switch self {
        case .miss: return 0
        case .bull: return 25
        case .bullseye: return 50
        default:
            // Basis-Zahl extrahieren (z. B. "T20" → 20)
            let numberString = String(rawValue.dropFirst())
            guard let baseNumber = Int(numberString) else { return 0 }
            
            // Mit Multiplikator verrechnen (S=1, D=2, T=3)
            return baseNumber * multiplier
        }
    }
    
    /// Multiplikator (1=Singles, 2=Doubles, 3=Triples)
    var multiplier: Int {
        if rawValue.hasPrefix("S") { return 1 }
        if rawValue.hasPrefix("D") { return 2 }
        if rawValue.hasPrefix("T") { return 3 }
        return 0
    }
    
    /// Nummer des Segments (1-20, 0 für Bull/Miss)
    var number: Int {
        if rawValue.hasPrefix("S") || rawValue.hasPrefix("D") || rawValue.hasPrefix("T") {
            let numberString = String(rawValue.dropFirst())
            return Int(numberString) ?? 0
        }
        if self == .bull || self == .bullseye { return 25 }
        return 0
    }
    
    /// Anzeige-Label für Buttons
    var displayLabel: String {
        switch self {
        case .miss: return "⊘"
        case .bull: return "25"
        case .bullseye: return "50"
        default: return String(rawValue.dropFirst())
        }
    }
    
    /// Farbe für Button-Hintergrund (nach Multiplikator)
    var colorIdentifier: String {
        switch self {
        case .miss: return "gray"
        case .bull: return "green"
        case .bullseye: return "red"
        default:
            let num = number
            let blackNumbers = [2, 3, 7, 8, 10, 12, 13, 14, 18, 20]
            if blackNumbers.contains(num) {
                return multiplier == 3 ? "red" : (multiplier == 2 ? "green" : "black")
            } else {
                return multiplier == 3 ? "red" : (multiplier == 2 ? "green" : "white")
            }
        }
    }
        
    /// String für Text-Farbe
    var textIdentifier: String {
        switch self {
        case .miss, .bull, .bullseye: return "white"
        default:
            let num = number
            let blackNumbers = [1, 4, 5, 6, 9, 11, 15, 16, 17, 19]
            return blackNumbers.contains(num) ? "white" : "black"
        }
    }
    
    // MARK: - Gruppen für UI-Organisation
    
    /// Alle Singles sortiert nach Dartboard-Reihenfolge
    static var singles: [DartSegment] {
        return dartboardOrder.compactMap {
            DartSegment(rawValue: "S\($0)")
        }
    }
    
    /// Alle Doubles sortiert nach Dartboard-Reihenfolge
    static var doubles: [DartSegment] {
        return dartboardOrder.compactMap {
            DartSegment(rawValue: "D\($0)")
        }
    }
    
    /// Alle Triples sortiert nach Dartboard-Reihenfolge
    static var triples: [DartSegment] {
        return dartboardOrder.compactMap {
            DartSegment(rawValue: "T\($0)")
        }
    }
    
    /// Alle Segmente für eine Zahl (S, D, T)
    static func segments(for number: Int) -> [DartSegment] {
        return [DartSegment.singles, DartSegment.doubles, DartSegment.triples]
            .flatMap { $0 }
            .filter { $0.number == number }
    }
}
