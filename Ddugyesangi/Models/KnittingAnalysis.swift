//
//  KnittingAnalysis.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/10/02.
//

import Foundation

struct KnittingAnalysis: Codable {
    let projectName: String
    let parts: [KnittingPart]
}

struct KnittingPart: Codable {
    let partName: String
    let startRow: Int
    let targetRow: Int
    let stitchGuide: [StitchGuide]
}

struct StitchGuide: Codable {
    let row: Int
    let targetStitch: Int
}
