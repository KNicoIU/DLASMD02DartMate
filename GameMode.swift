//
//  GameMode.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import Foundation

enum GameMode: String, CaseIterable, Codable, Identifiable {
    case threeOhOne = "301"
    case fiveOhOne = "501"
    case cricket = "Cricket"
    
    var id: String { rawValue }
    
    var startScore: Int {
        switch self {
        case .threeOhOne: return 301
        case .fiveOhOne: return 501
        case .cricket: return 0
        }
    }
}
