//
//  ActiveGameView.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import SwiftUI

struct ActiveGameView: View {
    @EnvironmentObject var gameVM: GameViewModel
    @EnvironmentObject var playerVM: PlayerViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showingCancelAlert = false
    @State private var showingMissConfirmation = false
    
    var game: Game? { gameVM.activeGame }
    
    var currentPlayer: Player? {
        guard let currentPlayerID = gameVM.currentPlayerID,
              let player = playerVM.player(by: currentPlayerID) else { return nil }
        return player
    }
    
    var displayPlayers: [(id: UUID, player: Player)] {
        guard let game = game else { return [] }
        return game.playerIDs.compactMap { playerID in
            guard let player = playerVM.player(by: playerID) else { return nil }
            return (id: playerID, player: player)
        }
    }
    
    var body: some View {
        if game == nil {
            VStack {
                Text("Kein aktives Spiel")
                    .font(.headline)
                Button("Zurück zum Dashboard") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            contentView
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 12) {
            headerView
            scoreboardView
            
            if !game!.isFinished, let player = currentPlayer {
                currentPlayerView(player: player)
            }
            
            if !game!.isFinished {
                dartboardView
            }
            
            if !game!.isFinished {
                missButton
            }
            
            if let bustMessage = gameVM.lastBustMessage {
                bustNotificationView(message: bustMessage)
            }
            
            if game!.isFinished, let winnerID = game!.winnerID,
               let winner = playerVM.player(by: winnerID) {
                gameOverView(winner: winner)
            }
            
            Spacer()
            actionsView
        }
        .navigationTitle("Laufendes Spiel")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Spiel wirklich abbrechen?", isPresented: $showingCancelAlert) {
            Button("Ja, abbrechen", role: .destructive) {
                gameVM.cancelGame()
                dismiss()
            }
            Button("Nein", role: .cancel) { }
        } message: {
            Text("Der aktuelle Spielverlauf wird nicht gespeichert.")
        }
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 4) {
                Text(game!.mode.rawValue)
                    .font(.headline)
                if !game!.rules.activeRulesDescription.isEmpty && game!.mode != .cricket {
                    Text("• \(game!.rules.activeRulesDescription)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
            Spacer()
            Text(game!.isFinished ? "Beendet" : "Aktiv")
                .font(.subheadline)
                .foregroundColor(game!.isFinished ? .green : .orange)
        }
        .padding(.horizontal)
    }
    
    private var scoreboardView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(displayPlayers, id: \.id) { item in
                    let playerID = item.id
                    let player = item.player
                    let score = game!.currentScore(for: playerID)
                    let isWinner = game!.isFinished && playerID == game!.winnerID
                    let isCurrentPlayer = gameVM.currentPlayerID == playerID && !game!.isFinished
                    
                    VStack(spacing: 8) {
                        Image(systemName: player.avatarSymbol)
                            .font(.title2)
                            .foregroundColor(isWinner ? .orange : .secondary)
                        
                        Text(player.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .frame(maxWidth: 100)
                        
                        Text("\(score)")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(isWinner ? .green : .primary)
                        
                        if isWinner {
                            Text("🏆")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        if isCurrentPlayer {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .frame(minWidth: 110)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isCurrentPlayer
                                ? Color.accentColor.opacity(0.15)
                                : Color(.systemGray6))
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func currentPlayerView(player: Player) -> some View {
        let throwsInVisit = gameVM.throwsInCurrentVisit(for: gameVM.currentPlayerID!)
        
        return VStack(spacing: 8) {
            HStack {
                Text("Am Wurf: \(player.name)")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { throwNum in
                        Circle()
                            .fill(throwNum <= throwsInVisit + 1 ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal)
            
            if let lastThrow = game?.throwHistory.last,
               let lastPlayer = playerVM.player(by: lastThrow.playerID) {
                HStack {
                    if lastThrow.isBust {
                        Text("❌ BUST – \(lastPlayer.name)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    } else {
                        Text("Letzter: \(lastPlayer.name) – \(lastThrow.segment ?? "\(lastThrow.points)")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: undoLastThrow) {
                        Label("Rückgängig", systemImage: "arrow.uturn.backward")
                            .font(.caption)
                    }
                    .disabled(!gameVM.canUndo)
                    .opacity(gameVM.canUndo ? 1.0 : 0.5)
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Bust-Nachricht View
    private func bustNotificationView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.headline)
                .foregroundColor(.orange)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(12)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var dartboardView: some View {
        VStack(spacing: 8) {
            DartboardView { segment in
                submitThrow(segment: segment)
            }
            .padding(.top, 8)
        }
    }
    
    private var missButton: some View {
        Button(action: { showingMissConfirmation = true }) {
            HStack {
                Image(systemName: "xmark.circle")
                Text("MISS (0 Punkte)")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .foregroundColor(.secondary)
        .padding(.horizontal)
    }
    
    private func gameOverView(winner: Player) -> some View {
        VStack(spacing: 12) {
            Text("Spiel beendet!")
                .font(.title2)
                .fontWeight(.bold)
            Text("\(winner.name) hat gewonnen!")
                .font(.headline)
                .foregroundColor(.green)
            if game!.rules.isDoubleOut || game!.rules.isMasterOut {
                Text("(mit \(game!.rules.activeRulesDescription))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var actionsView: some View {
        HStack {
            if !game!.isFinished {
                Button("Abbrechen", role: .destructive) {
                    showingCancelAlert = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Spiel beenden") {
                    gameVM.finishGame()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Zum Dashboard") {
                    gameVM.finishGame()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            
            
        }
        .padding()
    }
    
    private func submitThrow(segment: DartSegment) {
        guard let currentPlayerID = gameVM.currentPlayerID else { return }
        gameVM.recordThrow(segment: segment, for: currentPlayerID)
    }
    
    private func undoLastThrow() {
        gameVM.undoLastThrow()
    }
}
