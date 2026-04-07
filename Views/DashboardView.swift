//
//  DashboardView.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var gameVM: GameViewModel
    @State private var showingAddPlayer = false
    @State private var newPlayerName = ""
    @State private var showingGameSetup = false
    
    var body: some View {
        NavigationView {
            VStack {
                if playerVM.players.isEmpty {
                    ContentUnavailableView(
                        "Noch keine Spieler",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Füge deinen ersten Spieler hinzu, um zu starten.")
                    )
                } else {
                    List {
                        ForEach(playerVM.players) { player in
                            NavigationLink(destination: PlayerDetailView(player: player)
                                .environmentObject(playerVM)
                                .environmentObject(gameVM)
                            ) {
                                PlayerRowView(player: player)
                            }
                        }
                        .onDelete(perform: playerVM.deletePlayer)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("DartMate")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddPlayer = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingGameSetup = true }) {
                        Image(systemName: "gamecontroller")
                    }
                    .disabled(playerVM.players.count < 2)
                }
            }
            .sheet(isPresented: $showingAddPlayer) {
                AddPlayerSheet(
                    playerName: $newPlayerName,
                    onSave: {
                        playerVM.addPlayer(name: newPlayerName)
                        newPlayerName = ""
                    }
                )
                .environmentObject(playerVM)
                .environmentObject(gameVM)
            }
            .sheet(isPresented: $showingGameSetup) {
                GameSetupView(showingGameSetup: $showingGameSetup)
                    .environmentObject(playerVM)
                    .environmentObject(gameVM)
            }
            .fullScreenCover(isPresented: Binding(
                get: { gameVM.activeGame != nil },
                set: { _ in }
            )) {
                ActiveGameView()
                    .environmentObject(playerVM)
                    .environmentObject(gameVM)
            }
        }
    }
}

// MARK: - Subviews

struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        HStack {
            Image(systemName: player.avatarSymbol)
                .font(.title2)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.headline)
                Text("Ø \(String(format: "%.1f", player.average)) • Sieg: \(String(format: "%.0f", player.winRate))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddPlayerSheet: View {
    @Binding var playerName: String
    @Environment(\.dismiss) var dismiss
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name des Spielers", text: $playerName)
                    .autocapitalization(.words)
            }
            .navigationTitle("Neuer Spieler")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        onSave()
                        dismiss()
                    }
                    .disabled(playerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", role: .cancel) { dismiss() }
                }
            }
        }
    }
}
