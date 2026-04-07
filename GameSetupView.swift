//
//  GameSetupView.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import SwiftUI

struct GameSetupView: View {
    @Binding var showingGameSetup: Bool
    @EnvironmentObject var playerVM: PlayerViewModel
    @EnvironmentObject var gameVM: GameViewModel
    
    @State private var selectedMode: GameMode = .fiveOhOne
    @State private var selectedPlayerIDs: [UUID] = []
    @State private var rules = GameRules()
    
    /// Prüft ob Regeln für aktuellen Modus relevant sind
    var rulesRelevant: Bool {
        return selectedMode != .cricket
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Spielmodus")) {
                    Picker("Modus", selection: $selectedMode) {
                        ForEach(GameMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                
                if rulesRelevant {
                    // SPIELSTART
                    Section(header: Text("Spielstart")) {
                        HStack(spacing: 12) {
                            ForEach(StartRule.allCases) { rule in
                                RuleButton(
                                    title: rule.rawValue,
                                    isSelected: rules.startRule == rule
                                ) {
                                    rules.startRule = rule
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // SPIELENDE
                    Section(header: Text("Spielende")) {
                        HStack(spacing: 12) {
                            ForEach(EndRule.allCases) { rule in
                                RuleButton(
                                    title: rule.rawValue,
                                    isSelected: rules.endRule == rule
                                ) {
                                    rules.endRule = rule
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    // Cricket-Hinweis
                    Section(header: Text("Spielregeln")) {
                        Text("Cricket verwendet eigene Regeln")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("• Zahlen 15-20 + Bull müssen 3x getroffen werden")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Teilnehmer")) {
                    ForEach(playerVM.players) { player in
                        Button(action: {
                            if selectedPlayerIDs.contains(player.id) {
                                selectedPlayerIDs.removeAll { $0 == player.id }
                            } else {
                                selectedPlayerIDs.append(player.id)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedPlayerIDs.contains(player.id)
                                    ? "checkmark.circle.fill"
                                    : "circle")
                                Text(player.name)
                                Spacer()
                                Text("Ø \(String(format: "%.1f", player.average))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Neues Spiel")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        showingGameSetup = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Starten") {
                        guard selectedPlayerIDs.count >= 2 else { return }
                        gameVM.startGame(
                            mode: selectedMode,
                            playerIDs: selectedPlayerIDs,
                            rules: rules
                        )
                        showingGameSetup = false
                    }
                    .disabled(selectedPlayerIDs.count < 2)
                }
            }
        }
    }
}

// MARK: - RuleButton Component

struct RuleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .accentColor : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
