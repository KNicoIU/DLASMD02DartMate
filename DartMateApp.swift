//
//  DartMateApp.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import SwiftUI

@main
struct DartMateApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(playerViewModel)
                .environmentObject(gameViewModel)
                .onAppear {
                    gameViewModel.setPlayerViewModel(playerViewModel)
                }
        }
    }
}
