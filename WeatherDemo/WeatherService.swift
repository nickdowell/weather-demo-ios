//
//  WeatherService.swift
//  WeatherDemo
//
//  Created by Nick on 01/05/2017.
//  Copyright © 2017 Nick Dowell. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherService {
    
    let urlSession = URLSession(configuration: URLSessionConfiguration.ephemeral)

    func fetchCities(near coordinate: CLLocationCoordinate2D, completionHandler: @escaping (Response?) -> Swift.Void) {
        //
        // Note: api.openweathermap.org does not support HTTPS
        //
        let url = URL(string: "http://api.openweathermap.org/data/2.5/find?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&cnt=15&appid=56cb4841fe049d987586aea57480ceb9")
        urlSession.dataTask(with: url!) { (data, response, error) in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let apiResponse = Response(json: json!)
                else {
                    completionHandler(nil)
                    return
            }
            completionHandler(apiResponse)
            }.resume()
    }

    struct Response {
        let list: [Item]
        
        init?(json: [String: Any]) {
            guard
                let listJSON    = json["list"] as? [[String: Any]]
                else {
                    return nil
            }
            
            var list: [WeatherService.Item] = []
            for itemJSON in listJSON {
                guard let item = WeatherService.Item(json: itemJSON) else {
                    return nil
                }
                list.append(item)
            }
            
            self.list = list
        }
    }
    
    struct Item {
        let name: String
        let tempMax: Double
        let tempMin: Double
        let location: CLLocation
        let weatherDescription: String
        let icon: URL
        
        init?(json: [String: Any]) {
            guard
                let name = json["name"] as? String,
                let coord = json["coord"] as? [String: Any],
                let lat = coord["lat"] as? Double,
                let lon = coord["lon"] as? Double,
                let main = json["main"] as? [String: Any],
                let tempMax = main["temp_max"] as? Double,
                let tempMin = main["temp_min"] as? Double,
                let weather = (json["weather"] as? [[String: Any]])?.first,
                let description = weather["description"] as? String,
                let iconCode = weather["icon"] as? String,
                let iconURL = URL(string: "http://openweathermap.org/img/w/\(iconCode).png")
                else {
                    return nil
            }
            
            self.name = name
            self.tempMax = tempMax
            self.tempMin = tempMin
            self.location = CLLocation(latitude: lat, longitude: lon)
            self.weatherDescription = description
            self.icon = iconURL
        }
    }
}
