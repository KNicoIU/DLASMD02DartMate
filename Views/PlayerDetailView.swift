//
//  PlayerDetailView.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import SwiftUI

struct PlayerDetailView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var gameVM: GameViewModel
    let player: Player
    @State private var isEditing = false
    @State private var editedName = ""
    
    var body: some View {
        List {
            Section(header: Text("Profil")) {
                HStack {
                    Image(systemName: player.avatarSymbol)
                        .font(.system(size: 50))
                    if isEditing {
                        TextField("Name", text: $editedName)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Text(player.name)
                            .font(.title2)
                    }
                }
                .padding(.vertical, 8)
                
                if isEditing {
                    Button("Speichern") {
                        var updated = player
                        updated.name = editedName
                        playerVM.updatePlayer(updated)
                        isEditing = false
                    }
                    .font(.headline)
                    .foregroundColor(.accentColor)
                } else {
                    Button("Bearbeiten") {
                        editedName = player.name
                        isEditing = true
                    }
                    .font(.headline)
                }
            }
            
            Section(header: Text("Statistiken")) {
                StatisticRow(label: "Gespielte Spiele", value: "\(player.gamesPlayed)")
                StatisticRow(label: "Siege", value: "\(player.gamesWon)")
                StatisticRow(label: "Siegquote", value: "\(String(format: "%.1f", player.winRate))%")
                StatisticRow(label: "3-Dart Average", value: String(format: "%.2f", player.average))
                StatisticRow(label: "Checkouts", value: "\(player.checkouts)")
                StatisticRow(label: "Höchster Checkout", value: "\(player.highestCheckout)")
            }
        }
        .navigationTitle("Spieler")
        .listStyle(.insetGrouped)
    }
}

struct StatisticRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
