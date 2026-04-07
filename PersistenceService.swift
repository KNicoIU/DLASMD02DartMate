//
//  PersistenceService.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import Foundation

final class PersistenceService {
    static let shared = PersistenceService()
    private init() {}
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let players = "dartmate_players"
        static let games = "dartmate_games"
    }
    
    // MARK: - Players
    func savePlayers(_ players: [Player]) {
        encodeAndSave(players, forKey: Keys.players)
    }
    
    func loadPlayers() -> [Player] {
        decodeOrReturnEmpty(forKey: Keys.players)
    }
    
    // MARK: - Games
    func saveGames(_ games: [Game]) {
        encodeAndSave(games, forKey: Keys.games)
    }
    
    func loadGames() -> [Game] {
        decodeOrReturnEmpty(forKey: Keys.games)
    }
    
    // MARK: - Private Helpers
    private func encodeAndSave<T: Codable>(_ items: [T], forKey key: String) {
        do {
            let encoded = try JSONEncoder().encode(items)
            defaults.set(encoded, forKey: key)
        } catch {
            print("❌ Fehler beim Speichern von \(key): \(error.localizedDescription)")
        }
    }
    
    private func decodeOrReturnEmpty<T: Codable>(forKey key: String) -> [T] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            print("❌ Fehler beim Laden von \(key): \(error.localizedDescription)")
            return []
        }
    }
}
