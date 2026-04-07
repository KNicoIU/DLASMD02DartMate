//
//  DartboardView.swift
//  DartMate
//
//  Created by Nicolas Kersten on 02.04.26.
//


import SwiftUI

struct DartboardView: View {
    let onSegmentTap: (DartSegment) -> Void
    @State private var selectedSegment: DartSegment?
    
    // Dartboard-Abmessungen
    private let boardSize: CGFloat = 340
    private let center: CGPoint = CGPoint(x: 170, y: 170)
    
    // Ring-Radius (von außen nach innen)
    private let doubleRingOuter: CGFloat = 170
    private let doubleRingInner: CGFloat = 155
    private let tripleRingOuter: CGFloat = 110
    private let tripleRingInner: CGFloat = 95
    private let singleOuter: CGFloat = 155
    private let singleInner: CGFloat = 110
    private let bullOuter: CGFloat = 30
    private let bullInner: CGFloat = 15
    
    var body: some View {
        ZStack {
            // Hintergrund
            Circle()
                .fill(Color(.systemGray6))
                .frame(width: boardSize + 42, height: boardSize + 42)
                .shadow(radius: 5)
            
            // Dartboard Canvas
            ZStack {
                        ForEach(DartSegment.dartboardOrder, id: \.self) { number in
                            NumberButton(
                                number: number,
                                angle: DartSegment.angle(for: number),
                                radius: 182
                            ) {
                                if let segment = DartSegment(rawValue: "S\(number)") {
                                    onSegmentTap(segment)
                                }
                            }
                        }
                    }
                    .frame(width: boardSize + 40, height: boardSize + 40)
            
            ZStack {
                // Doubles Ring
                ForEach(DartSegment.dartboardOrder, id: \.self) { number in
                    DartboardSegment(
                        number: number,
                        innerRadius: doubleRingInner,
                        outerRadius: doubleRingOuter,
                        startAngle: DartSegment.angle(for: number) - 9,
                        endAngle: DartSegment.angle(for: number) + 9,
                        color: segmentColor(for: number, multiplier: 2),
                        label: "",
                        multiplier: "D"
                    ) {
                        if let segment = DartSegment(rawValue: "D\(number)") {
                            onSegmentTap(segment)
                        }
                    }
                }
                
                // Triples Ring
                ForEach(DartSegment.dartboardOrder, id: \.self) { number in
                    DartboardSegment(
                        number: number,
                        innerRadius: tripleRingInner,
                        outerRadius: tripleRingOuter,
                        startAngle: DartSegment.angle(for: number) - 9,
                        endAngle: DartSegment.angle(for: number) + 9,
                        color: segmentColor(for: number, multiplier: 3),
                        label: "",
                        multiplier: "T"
                    ) {
                        if let segment = DartSegment(rawValue: "T\(number)") {
                            onSegmentTap(segment)
                        }
                    }
                }
                
                // Singles Outer
                ForEach(DartSegment.dartboardOrder, id: \.self) { number in
                    DartboardSegment(
                        number: number,
                        innerRadius: tripleRingOuter,
                        outerRadius: doubleRingInner,
                        startAngle: DartSegment.angle(for: number) - 9,
                        endAngle: DartSegment.angle(for: number) + 9,
                        color: segmentColor(for: number, multiplier: 1),
                        label: "",
                        multiplier: ""
                    ) {
                        if let segment = DartSegment(rawValue: "S\(number)") {
                            onSegmentTap(segment)
                        }
                    }
                }
                
                // Singles Inner
                ForEach(DartSegment.dartboardOrder, id: \.self) { number in
                    DartboardSegment(
                        number: number,
                        innerRadius: bullOuter,
                        outerRadius: tripleRingInner,
                        startAngle: DartSegment.angle(for: number) - 9,
                        endAngle: DartSegment.angle(for: number) + 9,
                        color: segmentColor(for: number, multiplier: 1),
                        label: "",
                        multiplier: ""
                    ) {
                        if let segment = DartSegment(rawValue: "S\(number)") {
                            onSegmentTap(segment)
                        }
                    }
                }
                
                // Outer Bull
                Button(action: { onSegmentTap(.bull) }) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: bullOuter * 2)
                }
                .buttonStyle(.plain)
                
                // Bullseye
                Button(action: { onSegmentTap(.bullseye) }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: bullInner * 2)
                }
                .buttonStyle(.plain)
            }
            .frame(width: boardSize, height: boardSize)
        }
    }
    
    /// Dartboard-Farben
    private func segmentColor(for number: Int, multiplier: Int) -> Color {
        let blackNumbers = [2, 3, 7, 8, 10, 12, 13, 14, 18, 20]
        let isBlack = blackNumbers.contains(number)
        
        if multiplier == 2 { // Doubles
            return isBlack ? .green : .red
        } else if multiplier == 3 { // Triples
            return isBlack ? .red : .green
        } else { // Singles
            return isBlack ? .black : .white
        }
    }
}

// MARK: - DartboardSegment Component

struct DartboardSegment: View {
    let number: Int
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let label: String
    let multiplier: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                SegmentShape(
                    innerRadius: innerRadius,
                    outerRadius: outerRadius,
                    startAngle: startAngle,
                    endAngle: endAngle
                )
                .fill(color)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func offsetForAngle(_ angle: Double) -> CGSize {
        let radians = angle * .pi / 180
        let radius = (innerRadius + outerRadius) / 2
        let x = radius * cos(radians)
        let y = radius * sin(radians)
        return CGSize(width: x, height: y)
    }
}

// NumberButton Component für äußeren Zahlen-Ring
struct NumberButton: View {
    let number: Int
    let angle: Double
    let radius: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .offset(positionForAngle(angle))
        }
        .buttonStyle(.plain)
    }
    
    private func positionForAngle(_ angle: Double) -> CGSize {
        let radians = angle * .pi / 180
        let x = radius * cos(radians)
        let y = radius * sin(radians)
        return CGSize(width: x, height: y)
    }
}

// MARK: - SegmentShape

struct SegmentShape: Shape {
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        
        let startRad = startAngle * .pi / 180
        let endRad = endAngle * .pi / 180
        
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: Angle(radians: startRad),
            endAngle: Angle(radians: endRad),
            clockwise: false
        )
        
        let innerEndX = center.x + innerRadius * cos(endRad)
        let innerEndY = center.y + innerRadius * sin(endRad)
        path.addLine(to: CGPoint(x: innerEndX, y: innerEndY))
        
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: endRad),
            endAngle: Angle(radians: startRad),
            clockwise: true
        )

        path.closeSubpath()
        
        return path
    }
}
