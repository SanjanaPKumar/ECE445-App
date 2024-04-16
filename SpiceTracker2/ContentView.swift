//
//  ContentView.swift
//  SpiceTracker2
//
//  Created by Sanjana Kumar on 3/24/24.
//

import SwiftUI
import GoogleMaps
import CoreLocation
import MapKit

struct LocationView: View {
    @StateObject private var locationDataManager = LocationDataManager.shared
        @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.11035399200798, longitude: -88.23011653279755), //target on green location
                //latitude: 37.7749, longitude: -122.4194
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        var body: some View {
            Map(coordinateRegion: $region, showsUserLocation: true)
                // Map annotations can be added here if needed
            
            .onAppear {
                locationDataManager.startUpdatingLocationAndHeading()
            }
            .onChange(of: locationDataManager.currentLocation) { newLocation in
                guard let newLocation = newLocation else { return }
                region.center = newLocation.coordinate
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

struct LocationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationView()
    }
}

//LANDING PAGE
//Content View is main access point to app
struct ContentView: View {

//Variable for navigation bar
@State private var showGroceryPage = false
@State private var showIngredientDashboard = false
@State private var showLocationView = false

//static var currentPage: Page = .home
//    
//enum Page {
//    case home
//    case groceryPage
//    case ingredientDashboard
//    case locationView
//}

var body: some View {
    NavigationView {
        VStack {
//            switch ContentView.currentPage{
//            case .home:
//                ContentView()
//            case .groceryPage:
//                GroceryPage()
//            case .ingredientDashboard:
//                IngredientDashboard()
//            case .locationView:
//                LocationView()
//            }
            
            Text("Dry Kitchen Ingredient Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.blue)
                .multilineTextAlignment(.center)
                .padding(.top, -85.0)
            
            // Navigation to Grocery Page
                .navigationBarItems(leading: Button(action:  {showGroceryPage = true}) {
                    HStack {
                        Text("Grocery List")
                            .font(.callout)
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                    // Trigger navigation on button tap
                    .background(
                        NavigationLink(destination: GroceryPage(), isActive: $showGroceryPage) {
                        }
                    )
                })
            
            //Navigation to Ingredient Dashboard
                .navigationBarItems(leading: Button(action:  {showIngredientDashboard = true}) {
                    HStack {
                        Text("Ingredient Dashboard")
                            .font(.callout)
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                    // Trigger navigation on button tap
                    .background(
                        NavigationLink(destination: IngredientDashboard(), isActive: $showIngredientDashboard) {
                        }
                    )
                })
            //Navigation to Location View
                .navigationBarItems(leading: Button(action:  {showLocationView = true}) {
                    HStack {
                        Text("Location View")
                            .font(.callout)
                    }
                    .foregroundColor(.blue)
                    .font(.caption)
                    // Trigger navigation on button tap
                    .background(
                        NavigationLink(destination: LocationView(), isActive: $showLocationView) {
                        }
                    )
                })
            
        }
    }
    }
}

//Coding purposes,shows a preview of Landing page
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//GROCERY LIST
struct GroceryPage: View {
    var body: some View {
        Text("Grocery List")
            .font(.largeTitle)
            .fontWeight(.heavy)
            .foregroundColor(Color.blue)
            .multilineTextAlignment(.center)
            .padding()
        
    }}

//Coding purposes,shows a preview of the Grocery List page
struct GroceryPage_Previews: PreviewProvider {
    static var previews: some View {
        GroceryPage()
    }
}

//INGREDIENT DASHBOARD
class Spice: Identifiable, ObservableObject {
//    let id = UUID(); not sure if needed later
    @Published var name: String
    @Published var trackedWeight: Double
    @Published var lowerThreshold: Double

    //initilazation of Spice class
    init(name: String, trackedWeight: Double, lowerThreshold: Double) {
        self.name = name
        self.trackedWeight = trackedWeight
        self.lowerThreshold = lowerThreshold
    }
}

struct IngredientView: View {
    @ObservedObject var spice: Spice
    var viewModel: IngredientViewModel
    @State private var errorLowerThresholdMessage: String?

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Ingredient Name", text: $spice.name)
                .font(.headline)
                .onChange(of: spice.name) { newValue, _ in
                    viewModel.updateName(for: spice, newValue: newValue)
                }
            
            HStack {
                Text("Lower Threshold:")
                TextField("Lower Threshold", value: $spice.lowerThreshold, formatter: NumberFormatter())
                    .onChange(of: spice.lowerThreshold) { newValue, _ in
                        validateLowerThreshold()
                        viewModel.updateLowerThreshold(for: spice, newValue: newValue)
                    }
            }

//Since errorLowerThresholdMessage is optional string type
//Need to let become a string, so we can test if it !=nil
            if let errorMessage = errorLowerThresholdMessage
            {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            ProgressBar(trackedWeight: spice.trackedWeight, lowerThreshold: spice.lowerThreshold, isError: errorLowerThresholdMessage != nil)

        }
        .padding(.vertical, 25.0)
    }

    private func validateLowerThreshold() {
        if(spice.lowerThreshold < 0 ||
             spice.lowerThreshold > 500 || spice.lowerThreshold.truncatingRemainder(dividingBy: 1) != 0)
              {
            errorLowerThresholdMessage = "Threshold must be a whole number between 0 and 500 grams."
        } else {
            errorLowerThresholdMessage = nil
        }
    }
}

struct ProgressBar: View {
    var trackedWeight: Double
    var lowerThreshold: Double
    let maxWeight: Double = 500.0
    let minWeight: Double = 0.0
    var isError: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                //Entire Progress bar
                Rectangle()
                    .frame(width: geometry.size.width, height: 20)
                    .foregroundColor(.gray)
                    .opacity(0.2)
                
                //Filled section of progress bar
                Rectangle()
                    .frame(width: isError ? 0 : calculateProgressBarWidth(geometryWidth: geometry.size.width), height: 20)
                    .foregroundColor(isError ? .gray : (self.trackedWeight < self.lowerThreshold ? .red : .green))
                
                if !isError {
                    //Casting Double to Int, to remove trailing zeros
                    Text("\(Int(self.trackedWeight))g")
                        .padding(.leading, self.calculateTrackedWeightPosition(geometry: geometry, isError: isError))
                        .foregroundColor(.black)
                    
                    //Casting Double to Int, to remove trailing zeros
                    Text("\(Int(self.lowerThreshold))g")
                        .font(.caption)
                        .padding(.leading, 
                        self.calculateMarkerPosition(geometry: geometry, isError: isError))
                        .padding(.top, 60)
                        .foregroundColor(.black)
                }
                
                ThresholdLineMarker(width: self.calculateMarkerPosition(geometry: geometry, isError: isError))
                
            }
        }
        .frame(height: 20)
    }

    func calculateProgressBarWidth(geometryWidth: CGFloat) -> CGFloat {
        return (CGFloat(trackedWeight) / CGFloat(maxWeight)) * geometryWidth
    }

    func calculateTrackedWeightPosition(geometry: GeometryProxy, isError: Bool) -> CGFloat {
        if isError {
            return 0
        } else {
            let textPosition = (CGFloat(trackedWeight) / CGFloat(maxWeight)) * geometry.size.width
//-50 provides padding if trackedWeight lends the position of text too close to right edge
//min(,0) provides padding if trackedWeight lends the position of text too close to left edge
            return min(max(textPosition, 0), geometry.size.width - 50)
        }
    }
    
    func calculateMarkerPosition(geometry: GeometryProxy, isError: Bool) -> CGFloat {
        if isError {
            return 0
        } else {
            return (CGFloat(lowerThreshold) / CGFloat(maxWeight)) * geometry.size.width
        }
    }
}


struct ThresholdLineMarker: View {
    var width: CGFloat
    
    var body: some View {
        VStack {
            Rectangle()
                .padding(.bottom, -7.0)
                .frame(width: 2, height: 25)
                .foregroundColor(.black)
            Triangle()
                .frame(width: 10, height: 10)
                .foregroundColor(.black)
        }
        .offset(x: width)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Start from the top center
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        //Line to botton left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        //Line to botton right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        //Line to starting point
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

class IngredientViewModel: ObservableObject {
    @Published var ingredients: [Spice] = [
        Spice(name: "Ingredient 1", trackedWeight: 250, lowerThreshold: 100),
        Spice(name: "Ingredient 2", trackedWeight: 400, lowerThreshold: 150),
        Spice(name: "Ingredient 3", trackedWeight: 20, lowerThreshold: 50)
    ]
    
    // Update lowerThreshold for a specific ingredient
        func updateLowerThreshold(for ingredient: Spice, newValue: Double) {
            if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                ingredients[index].lowerThreshold = newValue
            }
        }
    // Update name for a specific ingredient
        func updateName(for ingredient: Spice, newValue: String) {
            if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                ingredients[index].name = newValue
            }
        }
}

struct IngredientDashboard: View {
    @StateObject var viewModel = IngredientViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Text("Ingredient Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(Color.blue)
                    .padding(.top, -100)

                ForEach(viewModel.ingredients) { ingredient in
                    IngredientView(spice: ingredient, viewModel: viewModel)
                }
                
            }
            .padding()
            
        }
    }
}

//Coding purposes,shows a preview of the Grocery List page
struct IngredientDashboard_Previews: PreviewProvider {
    static var previews: some View {
        IngredientDashboard()
    }
}
