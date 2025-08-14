//
//  PartDetailView.swift
//  Ddugyesangi
//
//  Created by JIHA YOON on 2025/08/14.
//

import Foundation
import SwiftUI

struct PartDetailView: View {
    let part: Part
    
    public var body: some View {
        VStack {
            HStack {
                Counter()
                Counter()
            }
        }
        .navigationTitle(part.name ?? "")
    }
}
