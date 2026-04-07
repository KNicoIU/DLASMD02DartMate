//
//  GameViewModel.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import Foundation
import Combine
import SwiftUI

class GameViewModel: ObservableObject {
    @Published var activeGame: Game?
    @Published var games: [Game] = []
    @Published var navigationPath = NavigationPath()
    @Published var lastBustMessage: String?
    @Published var lastInvalidStartMessage: String?
    
    private let persistence = PersistenceService.shared
    private var playerViewModel: PlayerViewModel?
    
    init() {}
    
    func setPlayerViewModel(_ viewModel: PlayerViewModel) {
        self.playerViewModel = viewModel
    }
    
    func loadGames() {
        games = persistence.loadGames()
    }
    
    func saveGames() {
        persistence.saveGames(games)
    }
    
    func startGame(mode: GameMode, playerIDs: [UUID], rules: GameRules) {
        var game = Game(mode: mode, playerIDs: playerIDs)
        game.rules = rules
        activeGame = game
        navigationPath.append("activeGame")
        lastBustMessage = nil
        lastInvalidStartMessage = nil
    }
    
    /// Wurf registrieren mit Visit-Reset bei Bust
    func recordThrow(segment: DartSegment, for playerID: UUID) {
        guard var game = activeGame, !game.isFinished else { return }
        
        let points = segment.points
        let segmentString = segment.rawValue
        
        var countsForScore = true
            if game.rules.startRule != .straight {
                let hasValidStart = game.playerHasValidStart(playerID)
                
                if !hasValidStart {
                    let isValidStart = game.isValidStart(segment: segmentString)
                    
                    if isValidStart {
                        game.hasValidStart.insert(playerID)
                        countsForScore = true
                        lastInvalidStartMessage = nil
                    } else {
                        countsForScore = false
                        let requiredRule = game.rules.startRule.rawValue
                        lastInvalidStartMessage = "Ungültiger Start! \(requiredRule) benötigt"
                    }
                }
            }
        
        if countsForScore && game.isBust(after: points, for: playerID, segment: segmentString) {
            let bustThrow = Throw(
                points: points,
                segment: segmentString,
                playerID: playerID,
                isCheckout: false,
                isBust: true,
                countsForScore: false
            )
            game.throwHistory.append(bustThrow)
            
            // Bust-Nachricht
            let currentScore = game.currentScore(for: playerID)
            let potential = currentScore - points
            var bustReason = ""
            
            if potential < 0 {
                bustReason = "\(potential) – unter 0"
            } else if potential == 1 {
                bustReason = "1 Punkt verbleibend"
            } else if potential == 0 {
                bustReason = "\(game.rules.endRule.rawValue) benötigt"
            }
            
            lastBustMessage = "BUST! (\(bustReason))"
            activeGame = game
            return
        }
        
        // Checkout-Prüfung
        let isCheckout = countsForScore && game.checkCheckout(for: playerID, lastThrowPoints: points, segment: segmentString)
        
        let newThrow = Throw(
            points: points,
            segment: segmentString,
            playerID: playerID,
            isCheckout: isCheckout,
            isBust: false,
            countsForScore: countsForScore
        )
        
        game.throwHistory.append(newThrow)
        
        if isCheckout {
            game.isFinished = true
            game.winnerID = playerID
            game.finishedAt = Date()
            updatePlayerStatistics(after: game)
        }
        
        activeGame = game
        if countsForScore {
            lastBustMessage = nil
        }
    }
    
    func undoLastThrow() {
        guard var game = activeGame, !game.throwHistory.isEmpty else { return }
        
        let removedThrow = game.throwHistory.removeLast()
        
        if !removedThrow.countsForScore && (game.rules.isDoubleIn || game.rules.isMastersIn) {
            lastInvalidStartMessage = "Ungültiger Start! \(game.rules.isMastersIn ? "Master" : "Double") benötigt"
        }
        
        if removedThrow.countsForScore && game.hasValidStart.contains(removedThrow.playerID) {
            let remainingValidThrows = game.throwHistory.filter {
                $0.playerID == removedThrow.playerID && $0.countsForScore
            }
            if remainingValidThrows.isEmpty {
                game.hasValidStart.remove(removedThrow.playerID)
            }
        }
        
        if game.isFinished {
            game.isFinished = false
            game.winnerID = nil
            game.finishedAt = nil
        }
        
        activeGame = game
        lastBustMessage = nil
    }
    
    var canUndo: Bool {
        guard let game = activeGame else { return false }
        return !game.throwHistory.isEmpty && !game.isFinished
    }
    
    private func updatePlayerStatistics(after game: Game) {
        guard let playerVM = playerViewModel else { return }
        
        for playerID in game.playerIDs {
            guard var player = playerVM.player(by: playerID) else { continue }
            let didWin = playerID == game.winnerID
            player.updateStatistics(after: game, didWin: didWin)
            playerVM.updatePlayer(player)
        }
    }
    
    func finishGame() {
        guard var game = activeGame else { return }
        game.isFinished = true
        game.finishedAt = Date()
        games.append(game)
        activeGame = nil
        navigationPath.removeLast(navigationPath.count)
        saveGames()
    }
    
    func cancelGame() {
        activeGame = nil
        navigationPath.removeLast(navigationPath.count)
        lastBustMessage = nil
        lastInvalidStartMessage = nil
    }
    
    /// Spieler-Rotation mit Bust-Berücksichtigung
    var currentPlayerID: UUID? {
        guard let game = activeGame, !game.isFinished else { return nil }
        guard !game.playerIDs.isEmpty else { return nil }
        
        let throwsVisit = game.throwHistory
        guard let lastThrow = throwsVisit.last else {
            return game.playerIDs.first
        }
        
        let lastPlayerID = lastThrow.playerID
        
        if lastThrow.isBust {
            guard let currentIndex = game.playerIDs.firstIndex(of: lastPlayerID) else {
                return game.playerIDs.first
            }
            let nextIndex = (currentIndex + 1) % game.playerIDs.count
            return game.playerIDs[nextIndex]
        }
        
        var throwsInCurrentVisit = 0
        for throwEntry in throwsVisit.reversed() {
            if throwEntry.playerID == lastPlayerID {
                throwsInCurrentVisit += 1
            } else {
                break
            }
        }
        
        if throwsInCurrentVisit < 3 {
            return lastPlayerID
        }
        
        guard let currentIndex = game.playerIDs.firstIndex(of: lastPlayerID) else {
            return game.playerIDs.first
        }
        let nextIndex = (currentIndex + 1) % game.playerIDs.count
        return game.playerIDs[nextIndex]
    }
    
    func throwsInCurrentVisit(for playerID: UUID) -> Int {
        guard let game = activeGame else { return 0 }
        var count = 0
        for throwEntry in game.throwHistory.reversed() {
            if throwEntry.playerID == playerID {
                count += 1
            } else {
                break
            }
        }
        return count
    }
}
