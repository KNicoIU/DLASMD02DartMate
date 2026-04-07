//
//  PlayerViewModel.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import Foundation
import Combine
import SwiftUI

class PlayerViewModel: ObservableObject {
    @Published var players: [Player] = []
    
    private let persistence = PersistenceService.shared
    private let defaults = UserDefaults.standard
    private let playersKey = "dartmate_players"
    
    init() {
        loadPlayers()
    }
    
    func loadPlayers() {
        players = persistence.loadPlayers()
    }
    
    func savePlayers() {
        persistence.savePlayers(players)
    }
    
    func addPlayer(name: String, avatarSymbol: String = "person.crop.circle") {
        let newPlayer = Player(name: name, avatarSymbol: avatarSymbol)
        players.append(newPlayer)
        savePlayers()
    }
    
    func deletePlayer(at offsets: IndexSet) {
        players.remove(atOffsets: offsets)
        savePlayers()
    }
    
    func updatePlayer(_ player: Player) {
        if let index = players.firstIndex(where: { $0.id == player.id }) {
            players[index] = player
            savePlayers()
        }
    }
    
    func player(by id: UUID) -> Player? {
        players.first { $0.id == id }
    }
}
