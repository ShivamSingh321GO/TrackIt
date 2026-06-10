//
//  ProjectDetailView.swift
//  TrackIt
//
//  Created by Antigravity on 6/4/26.
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    let onBack: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Back Button Navigation Bar
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back to Projects")
                    }
                    .font(.body)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, 8)
            
            // Project Title Section (Only shows a text with project name as requested)
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: project.colorHex))
                    .frame(width: 14, height: 14)
                
                Text(project.name)
                    .font(.title)
                    .bold()
            }
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
