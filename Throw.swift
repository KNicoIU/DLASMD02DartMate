//
//  Throw.swift
//  DartMate
//
//  Created by Nicolas Kersten on 01.04.26.
//


import Foundation

struct Throw: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var points: Int
    var segment: String?
    var playerID: UUID
    var isCheckout: Bool = false
    var isBust: Bool = false
    var countsForScore: Bool = true
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case points
        case segment
        case playerID
        case isCheckout
        case isBust
        case countsForScore
    }
}
