//
//  LocationInputView.swift
//  UberSwiftUI
//
//  Created by Stephen Dowless on 11/16/21.
//

import SwiftUI
import MapKit

struct RideLocationInputView: View {
    @State private var startLocationText = ""
    @EnvironmentObject var viewModel: LocationSearchViewModel
    @Binding var show: Bool
    var animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            LocationInputHeaderView(startLocationText: $startLocationText, destinationText: $viewModel.queryFragment)
                .matchedGeometryEffect(id: "LocationInput", in: animation)
                .frame(height: 200)
                .background(Color.white)
            
            LocationResultsView(config: .ride, show: $show)
        }
    }
}
