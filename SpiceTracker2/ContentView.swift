//
//  ContentView.swift
//  SpiceTracker2
//
//  Created by Sanjana Kumar on 3/24/24.
//

import SwiftUI
import FirebaseDatabase
import Firebase

//LANDING PAGE
//Content View is main access point to app
struct ContentView: View {

//Variable for navigation bar
@State private var showGroceryPage = false
@State private var showIngredientDashboard = false
var body: some View {
    NavigationView {
        VStack {
            Text("Dry Kitchen Ingredient Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.blue)
                .multilineTextAlignment(.center)
                .padding(.top, -85.0)
            
            Text("Ingredient Dashboard: Enter spice name and lower weight threshold value [0-500 grams] for each container")
                .padding(.all, 15.0)
            
            Text("Grocery List: List of spices running low")
                .padding(.leading, -16)
            
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
//INGREDIENT DASHBOARD
class Spice: Identifiable, ObservableObject {
//    let id = UUID(); not sure if needed later
    @Published var name: String
    @Published var trackedWeight: Double
    @Published var lowerThreshold: Double
    @Published var runningLow: Bool
    @Published var RFID_Number: String
    @Published var Box_Number: String

    //initilazation of Spice class
    init(name: String, trackedWeight: Double, lowerThreshold: Double,runningLow: Bool, RFID_Number: String,Box_Number: String) {
        self.name = name
        self.trackedWeight = trackedWeight
        self.lowerThreshold = lowerThreshold
        self.runningLow = runningLow
        self.RFID_Number = RFID_Number
        self.Box_Number = Box_Number
    }
}

struct IngredientView: View {
    @ObservedObject var spice: Spice
    var viewModel: IngredientViewModel
    @State private var errorLowerThresholdMessage: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Container \(spice.Box_Number):")
                TextField("Spice Name", text: $spice.name)
                    .font(.headline)
                    .onChange(of: spice.name) { _ in
                        updateSpiceInFirebase()
                    }
            }
            HStack {
                Text("Lower Threshold:")
                TextField("Lower Threshold", value: $spice.lowerThreshold, formatter: NumberFormatter())
                    .onChange(of: spice.lowerThreshold) { newValue, _ in
                        validateLowerThreshold()
                        updateSpiceInFirebase()
                        
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
    
    
    private func updateSpiceInFirebase() {
        guard let index = viewModel.ingredients.firstIndex(where: { $0.id == spice.id }) else {
            return
        }
        
        let updatedSpice = viewModel.ingredients[index]
        //For setting runningLow flag value correctly
        if (updatedSpice.lowerThreshold > updatedSpice.trackedWeight){
            updatedSpice.runningLow = true
        }else{
            updatedSpice.runningLow = false
        }
        
        let childReference = viewModel.ref.child("spices").child("\(index)")
        
        childReference.child("spiceName").setValue(updatedSpice.name)
        childReference.child("lowerThreshold").setValue(updatedSpice.lowerThreshold)
        childReference.child("runningLow").setValue(updatedSpice.runningLow)
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
    @Published var ingredients: [Spice] = []
     var ref: DatabaseReference = Database.database().reference()
            
        init() {
            fetchSpicesFromFirebase()
        }
        
    private func fetchSpicesFromFirebase() {
           let ref = Database.database().reference()
           ref.child("spices").observeSingleEvent(of: .value) { (snapshot, error) in
               if let error = error {
                   print("Error fetching spices:", error)
                   return
               }

               guard let spicesData = snapshot.value as? [[String: Any]] else {
                   print("Error: Unable to fetch data in spices")
                   return
               }
               var spices: [Spice] = []
               for spiceData in spicesData {
                   guard let name = spiceData["spiceName"] as? String,
                         let trackedWeight = spiceData["trackedWeight"] as? Double,
                         let lowerThreshold = spiceData["lowerThreshold"] as? Double,
                         let runningLow = spiceData["runningLow"] as? Bool,
                         let RFID_Number = spiceData["RFID_Number"] as? String,
                         let Box_Number = spiceData["Box_Number"] as? String else {
                       print("Error: Unable to parse spice data")
                       continue
                   }
                   let spice = Spice(name: name, trackedWeight: trackedWeight, lowerThreshold: lowerThreshold, runningLow: runningLow, RFID_Number: RFID_Number, Box_Number: Box_Number)
                   spices.append(spice)
               }
               
               DispatchQueue.main.async {
                   self.ingredients = spices
//                   print("Ingredients array:", self.ingredients)
               }
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

//GROCERY LIST
struct GroceryPage: View {
    @StateObject var viewModel = IngredientViewModel()
    var body: some View {
        Text("Grocery List")
            .font(.largeTitle)
            .fontWeight(.heavy)
            .foregroundColor(Color.blue)
            .multilineTextAlignment(.center)
            .padding()
        
        // Display only spices where runningLow is true
        List(viewModel.ingredients.filter { $0.runningLow }) { spice in
            Text(spice.name)
                .padding()
            
        }
    }
}

//Coding purposes,shows a preview of the Grocery List page
struct GroceryPage_Previews: PreviewProvider {
    static var previews: some View {
        GroceryPage()
    }
}
