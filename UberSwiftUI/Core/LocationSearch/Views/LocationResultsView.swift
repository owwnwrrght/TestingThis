//
//  LocationResultsView.swift
//  UberSwiftUI
//
//  Created by Stephan Dowless on 12/4/21.
//

import SwiftUI

enum LocationResultsViewConfig {
    case ride
    case savedLocations(SavedLocationOptions)
}

struct LocationResultsView: View {
    let config: LocationResultsViewConfig
    
    @EnvironmentObject var viewModel: LocationSearchViewModel
    @Binding var show: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.searchResults, id: \.self) { result in
                    LocationSearchResultCell(title: result.title, subtitle: result.subtitle)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                self.viewModel.selectLocation(location: result, forConfig: config)
                                self.show.toggle()
                            }
                        }
                }
            }
        }
        .background(Color.theme.backgroundColor)
        .frame(width: UIScreen.main.bounds.width)
    }
}
