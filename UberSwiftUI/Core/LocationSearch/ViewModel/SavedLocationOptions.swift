//
//  SavedLocationOptions.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 12/4/21.
//

import Foundation

enum SavedLocationOptions: Int, CaseIterable, Decodable {
    case home
    case work
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .work: return "Work"
        }
    }
    
    var imageName: String {
        switch self {
        case .home: return "house.circle.fill"
        case .work: return "archivebox.circle.fill"
        }
    }
    
    var databaseKey: String {
        switch self {
        case .home: return "homeLocation"
        case .work: return "workLocation"
        }
    }
}
