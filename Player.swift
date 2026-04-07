//
//  Player.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import Foundation

struct Player: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var avatarSymbol: String = "person.crop.circle"
    
    // Aggregierte Statistiken (werden bei Spielabschluss aktualisiert)
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalDartsThrown: Int = 0
    var totalScoreAchieved: Int = 0
    var checkouts: Int = 0
    var highestCheckout: Int = 0
    
    // Computed Properties für UI-Darstellung
    var average: Double {
        guard totalDartsThrown > 0 else { return 0.0 }
        return Double(totalScoreAchieved) / Double(totalDartsThrown) * 3.0
    }
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }
    
    var checkoutRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(checkouts) / Double(gamesPlayed) * 100
    }
    
    // Mutierende Methode zur Statistik-Aktualisierung
    mutating func updateStatistics(after game: Game, didWin: Bool) {
        gamesPlayed += 1
        if didWin { gamesWon += 1 }
        
        let playerThrows = game.throwHistory.filter { $0.playerID == id }
        totalDartsThrown += playerThrows.count
        totalScoreAchieved += playerThrows.reduce(0) { $0 + $1.points }
        
        let checkoutThrows = playerThrows.filter { $0.isCheckout }
        checkouts += checkoutThrows.count
        if let maxCheckout = checkoutThrows.map({ $0.points }).max(),
           maxCheckout > highestCheckout {
            highestCheckout = maxCheckout
        }
    }
}
