//
//  ViewController.swift
//  WeatherDemo
//
//  Created by Nick on 01/05/2017.
//  Copyright © 2017 Nick Dowell. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var resultsTableView: UITableView!
    
    let weatherService = WeatherService()
    var response: WeatherService.Response?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.response = WeatherService.cachedResponse
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text {
            search(text)
        }
        return true
    }
    
    func search(_ string: String) {
        CLGeocoder().geocodeAddressString(string) { (placemarks, error) in
            if let location = placemarks?.first?.location {
                self.fetchWeatherData(near: location.coordinate)
            }
        }
    }
    
    func fetchWeatherData(near coordinate: CLLocationCoordinate2D) {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        
        weatherService.fetchCities(near: coordinate) { (response) in
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem = nil
                if let response = response {
                    self.response = response
                    self.resultsTableView.reloadData()
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.response?.list.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultsTableViewCell", for: indexPath) as! ResultsTableViewCell
        
        if let item = self.response?.list[indexPath.row] {
            cell.iconImageView.image = UIImage(named: item.iconCode)
            cell.nameLabel.text = item.name
            cell.minTempLabel.text = "↧ \(formatTemperature(kelvin: item.tempMin))"
            cell.maxTempLabel.text = "↥ \(formatTemperature(kelvin: item.tempMax))"
            cell.weatherLabel.text = item.weatherMain
        }
        
        return cell
    }
    
    func formatTemperature(kelvin value: Double) -> String {
        let formatter = MeasurementFormatter()
        let measurement = Measurement(value: value, unit: UnitTemperature.kelvin)
        return formatter.string(from: measurement)
    }
}
