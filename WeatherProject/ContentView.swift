//
//  ContentView.swift
//  WeatherProject
//
//  Created by George Muresan on 5/28/20.
//  Copyright © 2020 George Muresan. All rights reserved.
//

import SwiftUI
import CoreLocation
import SwiftyJSON
import SDWebImageSwiftUI


struct ContentView: View {
    
    @State var managerDelgate = LocationManager() //used for location services
    @State var manager = CLLocationManager() // used for location services
    @State var forecastData : [dataType] = [] //storing the 5day forecast data
    @State var hourlyData : [hourlyType] = [] //storing the 12hour forecast data
    @State var error = ""
    
    var body: some View {
        
        NavigationView{
            
            VStack{
                
                //error catching for no data input
                if forecastData.count == 0 {
                    
                    if self.error != ""{
                        
                        Text(error)
                    }
                    else{
                        
                        Indicator()
                    }
                    
                }
                else{
                    //list view for user interface
                    List {
                        //Horizontal scroll for 5day forecast
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack(spacing: 18){
                                ForEach(self.forecastData) { i in
                                    //adding image for weather
                                    AnimatedImage(url: URL(string: i.icon)!).resizable().frame(width: 80, height: 45)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("\(i.date)").bold()
                                        Text(i.phrase).italic()
                                        Text("Max \(i.max) F")
                                        Text("Min \(i.min) F")
                                    }
                                }//end of ForEach loop
                                
                                
                            }.padding(.vertical).background(Color.blue.opacity(0.4)).edgesIgnoringSafeArea(.all)
                        }//end of Daily ScrollView
                        
                        ScrollView(.vertical, showsIndicators: false){
                        
                            VStack(alignment: .leading, spacing: 18){
                                Text("Hourly Temperature").font(.title)
                                ForEach(self.hourlyData) { i in
                                    
                                    Text("\(i.hour)").bold().font(.headline).underline(true, color: Color.black)
                            
                                    HStack(spacing: 6) {
                                        Text("Temp: \(i.temperature.Value) F")
                                        Spacer()
                                        Text(i.phrase).italic()
                                        Spacer()
                                        AnimatedImage(url: URL(string: i.iconPic)!).resizable().frame(width: 80, height: 45)
                                    }
                                } //end of ForEach loop
                                
                                
                            }.padding(.vertical).background(Color.gray.opacity(0.5))
                        }//end of Vertical ScrollView
                        
                    }//end of list
                    
                }//end of else
                
                }.navigationBarTitle("Your Weather Forecast")
            .onAppear {
                
                self.manager.delegate = self.managerDelgate
                //enabling location services for user
                if CLLocationManager.locationServicesEnabled(){
                    
                    let status = CLLocationManager.authorizationStatus()
                    if status == .denied{
                        self.error = "Enable Location Services" //user alert for location privacy
                    }
                    else{
                        self.manager.requestLocation()
                    }
                }
                
                self.manager.requestAlwaysAuthorization()
                
                //Collecting 5day Forecast Data  - using - NotificationCenter
                NotificationCenter.default.addObserver(forName: NSNotification.Name("Forecast"), object: nil, queue: .main) { (noti) in
                    
                    let json = noti.userInfo!["data"] as! JSON
                    
                    if let forecast = json.dictionary!["DailyForecasts"]?.arrayValue{
                        
                        for i in 0..<forecast.count{
                            
                            if let temp = forecast[i].dictionary!["Temperature"],
                                let epochdate = forecast[i].dictionary!["EpochDate"]?.intValue{
                                
                                let timeInterval = Double(epochdate)
                                let NEWepochdate = Date(timeIntervalSince1970: timeInterval)
            
                                let dateformat = DateFormatter()
                                dateformat.dateStyle = .medium
                                dateformat.timeStyle = .none
                                dateformat.locale = Locale(identifier: "en_US")
                                
                                let DateInFormat = dateformat.string(from: NEWepochdate)
                                
                                let max = temp["Maximum"].dictionary!["Value"]!.intValue
                                
                                let min = temp["Minimum"].dictionary!["Value"]!.intValue
                                
                                let day = forecast[i].dictionary!["Day"]
                                
                                let iconcode = day!.dictionary!["Icon"]!.intValue
                                
                                let iconurl = "https://developer.accuweather.com/sites/default/files/\(iconcode < 10 ? "0" : "")\(iconcode)-s.png"
                                
                                
                                let phrase = day!.dictionary!["IconPhrase"]!.stringValue
                                
                                self.forecastData.append(dataType(id: i, icon: iconurl, phrase: phrase, min: "\(min)", max: "\(max)", date: DateInFormat))
                                
                            }//end of if let statement
                            
                        }//end of for loop

                    }
                    
                    
                }//end of NotificationCenter observer
                
                
                //Collecting 12hour Forecast Data  - using - NotificationCenter
                NotificationCenter.default.addObserver(forName: NSNotification.Name("Hourly"), object: nil, queue: .main) { (noti) in
                    
                    let jsonHourly = noti.userInfo!["data"] as! JSON
                    let hourlyarray = jsonHourly.arrayValue
                    var counter = 0
                    for item in hourlyarray {
                        
                        let temp = item["Temperature"]
                        let tempValue = temp["Value"].intValue
                        let unitType = temp["UnitType"].intValue
                        let unit = temp["Unit"].stringValue
                        
                        //temperature object declared
                        let tempobj = temperature(Unit: unit, UnitType: unitType, Value: tempValue)
                        
                        let iconcode = item["WeatherIcon"].intValue
                        let iconurl = "https://developer.accuweather.com/sites/default/files/\(iconcode < 10 ? "0" : "")\(iconcode)-s.png"
                        let phrase = item["IconPhrase"].stringValue
                        
                        counter = counter + 1
                        //starting hour collection and formatting
                        let epochhour = item["EpochDateTime"].intValue
                        let timeInterval2 = Double(epochhour)
                        let NEWepochdate = Date(timeIntervalSince1970: timeInterval2)
                        let hourformat = DateFormatter()
                        hourformat.dateStyle = .none
                        hourformat.timeStyle = .short
                        hourformat.locale = Locale(identifier: "en_US")
                        //hour declaration
                        let HourInFormat = hourformat.string(from: NEWepochdate)
                        //hour object
                        let hourlyobj = hourlyType(id: counter, iconPic: iconurl, phrase: phrase, hour: HourInFormat, temperature: tempobj)
                        //adding object to hourlyData array
                        self.hourlyData.append(hourlyobj)
                    }//end of for loop
                    
                }//end of NotificationCenter observer
                
                //error observer...
                NotificationCenter.default.addObserver(forName: NSNotification.Name("Error"), object: nil, queue: .main) { (_) in
                    
                    if self.error == ""{
                        
                        self.error = "Enable Location Services"
                    }
                }//end of NotificationCenter observer
            }//end of NavBar
        }//end of NavigationView
    } // end of Body - View
}//end of Content - View


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//Location services utilized
class LocationManager : NSObject, CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied{
            print("Denied")
            NotificationCenter.default.post(name: NSNotification.Name("Error"), object: nil)
        }
        else{
            print("Authorized")
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        NotificationCenter.default.post(name: NSNotification.Name("Error"), object: nil)
    }
    
    
    //This function will use the location of the iDevice and the coordinates to find the geoposition of those coordinates
    //In this case, its Annapolis, MD and it will automatically use that location for gathering the data
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let lat = "\(locations.last!.coordinate.latitude)"
        let long = "\(locations.last!.coordinate.longitude)"
        let lkeyurl = "http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=\(apiKey)&q=\(lat)%2C%20\(long)"
        
        var req = URLRequest(url: URL(string: lkeyurl)!)
        req.httpMethod = "GET"
        let session = URLSession(configuration: .default)
        
        session.dataTask(with: req) { (data, _, err) in
            if err != nil{
                    print((err?.localizedDescription)!)
                    return
            }
            
        let json = try! JSON(data:data!)
        
        let lKey = json.dictionary!["Key"]?.stringValue
            
        let forecasturl = "http://dataservice.accuweather.com/forecasts/v1/daily/5day/\(lKey!)?apikey=\(apiKey)"
        
        var req1 = URLRequest(url: URL(string: forecasturl)!)
        req1.httpMethod = "GET"
        let forecastsess = URLSession(configuration: .default)
        
        forecastsess.dataTask(with: req1) { (data1, _, err) in
            if err != nil{
                print((err?.localizedDescription)!)
                return
            }
            
        let json1 = try! JSON(data: data1!)
        
        //calling observable for 5day forecast
        NotificationCenter.default.post(name: NSNotification.Name("Forecast"), object: nil, userInfo: ["data":json1])
        
        }.resume()
        
        let hourlyurl = "http://dataservice.accuweather.com/forecasts/v1/hourly/12hour/\(lKey!)?apikey=\(apiKey)"
        
        var req2 = URLRequest(url: URL(string: hourlyurl)!)
        req2.httpMethod = "GET"
        let hourlysess = URLSession(configuration: .default)
        
        hourlysess.dataTask(with: req2) { (data2, _, err) in
            if err != nil{
                print((err?.localizedDescription)!)
                return
            }
            let json2 = try! JSON(data: data2!)
            
            //calling observabel for 12hour forecast
            NotificationCenter.default.post(name: NSNotification.Name("Hourly"), object: nil, userInfo: ["data":json2])
        }.resume()
    }.resume()
        
    }//end of Location Manager function
}//end of Location Manager class


//Structs for the dataTypes used to collect data from API's

struct dataType: Identifiable {
    
    var id: Int
    var icon: String
    var phrase: String
    var min: String
    var max: String
    var date: String

}

struct hourlyType: Identifiable {
    
    var id: Int
    var iconPic: String
    var phrase: String
    var hour: String
    var temperature: temperature
    
}

struct temperature: Codable {

    var Unit: String
    var UnitType: Int
    var Value: Int
}

struct Indicator : UIViewRepresentable {
    
    func makeUIView(context: UIViewRepresentableContext<Indicator>) -> UIActivityIndicatorView {
        
        let view = UIActivityIndicatorView(style: .large)
        view.startAnimating()
        return view
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<Indicator>){
        
    }
}


//personal API key used for AccuWeather website
let apiKey  = "0xZX7OnAt24R4puXT3zvFIXdQci8N5fk"
