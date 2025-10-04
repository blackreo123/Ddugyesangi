//
//  KnittingAnalysis.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/02.
//

import Foundation

struct KnittingAnalysis: Codable, Equatable {
    let projectName: String
    let parts: [KnittingPart]
}

struct KnittingPart: Codable, Equatable {
    let partName: String
    let targetRow: Int
    let stitchGuide: [StitchGuide]
}

struct StitchGuide: Codable, Equatable {
    let row: Int
    let targetStitch: Int
}
