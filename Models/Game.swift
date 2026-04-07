//
//  Game.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import Foundation

struct Game: Identifiable, Codable {
    var id: UUID = UUID()
    var mode: GameMode
    var playerIDs: [UUID]
    var throwHistory: [Throw] = []
    var isFinished: Bool = false
    var winnerID: UUID?
    var createdAt: Date = Date()
    var finishedAt: Date?
    
    /// Spielregeln
    var rules: GameRules = GameRules()
    
    /// Trackt welcher Spieler bereits gültig gestartet hat (Double-In/Masters-In)
    var hasValidStart: Set<UUID> = []
    
    /// Trackt Score zu Beginn jedes Visits pro Spieler
    var visitStartScores: [UUID: Int] = [:]
    
    enum CodingKeys: String, CodingKey {
        case id, mode, playerIDs, throwHistory, isFinished, winnerID, createdAt, finishedAt, rules
        case hasValidStart = "validStartPlayers"
        case visitStartScores = "visitScores"
    }
    
    init(mode: GameMode, playerIDs: [UUID], rules: GameRules = GameRules()) {
        self.mode = mode
        self.playerIDs = playerIDs
        self.rules = rules
        
        if rules.startRule == .straight {
            self.hasValidStart = Set(playerIDs)
        } else {
            self.hasValidStart = []
        }
    }
    
    /// Berechnet die aktuelle Restpunktzahl für einen Spieler
    func currentScore(for playerID: UUID) -> Int {
        guard !isFinished else { return 0 }
        let startScore = mode.startScore
        let playerThrows = throwHistory.filter {
            $0.playerID == playerID && $0.countsForScore
        }
        let totalPoints = playerThrows.reduce(0) { $0 + $1.points }
        return max(0, startScore - totalPoints)
    }
    
    /// Berechnet Score nur mit Würfen VOR dem aktuellen Visit
    func scoreBeforeCurrentVisit(for playerID: UUID) -> Int {
        let startScore = mode.startScore
        
        // Alle Würfe dieses Spielers holen
        let playerThrows = throwHistory.filter { $0.playerID == playerID }
        
        // Visit-Grenzen bestimmen (alle 3 Würfe = 1 Visit)
        let visitNumber = playerThrows.count / 3
        let throwsBeforeVisit = playerThrows.prefix(visitNumber * 3)
        
        // Nur Würfe die für Score zählen
        let validThrows = throwsBeforeVisit.filter { $0.countsForScore }
        let totalPoints = validThrows.reduce(0) { $0 + $1.points }
        
        return startScore - totalPoints
    }
    
    /// Setzt aktuellen Visit zurück
    mutating func resetCurrentVisit(for playerID: UUID) {
        // Alle Würfe des aktuellen Visits finden
        let playerThrows = throwHistory.filter { $0.playerID == playerID }
        let throwsInCurrentVisit = playerThrows.count % 3
        
        // Wenn noch keine 3 Würfe, dann alle Würfe dieses Visits entfernen
        if throwsInCurrentVisit > 0 {
            var throwsToRemove: [Int] = []
            var count = 0
            for (index, throwEntry) in throwHistory.enumerated().reversed() {
                if throwEntry.playerID == playerID {
                    if count < throwsInCurrentVisit {
                        throwsToRemove.append(index)
                        count += 1
                    } else {
                        break
                    }
                }
            }
            
            // Würfe entfernen
            for index in throwsToRemove.sorted(by: >) {
                throwHistory.remove(at: index)
            }
        }
    }
    
    /// Prüft ob Wurf ein Double ist
    func isDouble(segment: String?) -> Bool {
        guard let segment = segment else { return false }
        return segment.hasPrefix("D") || segment == "Bullseye"
    }
    
    /// Prüft ob Wurf ein Treble ist
    func isTreble(segment: String?) -> Bool {
        guard let segment = segment else { return false }
        return segment.hasPrefix("T")
    }
    
    /// Prüft ob Wurf ein Master ist (Double oder Treble)
    func isMaster(segment: String?) -> Bool {
        return isDouble(segment: segment) || isTreble(segment: segment)
    }
    
    /// Prüft ob Spieler bereits gültig gestartet hat
    func playerHasValidStart(_ playerID: UUID) -> Bool {
        return hasValidStart.contains(playerID)
    }
    
    /// Prüft ob Wurf gültiger Start ist und markiert Spieler
    func isValidStart(segment: String?) -> Bool {
        guard mode != .cricket else { return true }
        
        switch rules.startRule {
        case .straight:
            return true
        case .double:
            return isDouble(segment: segment)
        case .master:
            return isMaster(segment: segment)
        }
    }
    
    /// Bust-Prüfung mit allen Regeln
    func isBust(after points: Int, for playerID: UUID, segment: String?) -> Bool {
        guard mode != .cricket else { return false }
        guard hasValidStart.contains(playerID) else { return false }
        
        let currentScore = self.currentScore(for: playerID)
        let potential = currentScore - points
        
        // Unter 0 → Immer Bust
        if potential < 0 { return true }
        
        // Exakt 0 aber End-Regel nicht erfüllt ODER 1 → Bust
        if potential == 1 || potential == 0 {
            switch rules.endRule {
            case .straight:
                return false  // Immer gültig
            case .double:
                return !isDouble(segment: segment)
            case .master:
                return !isMaster(segment: segment)
            }
        }
        
        return false
    }
    
    /// Checkout-Prüfung mit allen Regeln
    func checkCheckout(for playerID: UUID, lastThrowPoints: Int, segment: String?) -> Bool {
        guard mode != .cricket else { return false }
        guard hasValidStart.contains(playerID) else { return false }
        
        let currentScore = self.currentScore(for: playerID)
        let potential = currentScore - lastThrowPoints
        
        // Exakt 0 erreicht?
        guard potential == 0 else { return false }
        
        // End-Regel prüfen
        switch rules.endRule {
        case .straight:
            return true  // Immer gültig
        case .double:
            return isDouble(segment: segment)
        case .master:
            return isMaster(segment: segment)
        }
    }
    
    /// Aktuelle Runde basierend auf Würfen
    var currentRound: Int {
        guard let firstPlayerID = playerIDs.first else { return 1 }
        let throwsForFirstPlayer = throwHistory.filter { $0.playerID == firstPlayerID }
        return throwsForFirstPlayer.count / 3 + 1
    }
}
