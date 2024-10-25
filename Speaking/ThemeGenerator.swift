//
//  TextGenerator.swift
//  Speaking
//
//  Created by m_sasaki on 2024/10/21.
//

import Foundation

struct ThemeGenerator {
    static func generateThemes(basedOn favorites: [String], maxThemes: Int) -> [String] {
        var generatedThemes: [String] = []
        
        for i in 0..<maxThemes {
            // ChatGPT API を使ったテーマ生成をここに実装する予定
            let newTheme = "Theme \(i)"
            generatedThemes.append(newTheme)
        }
        
        return generatedThemes
    }
}
