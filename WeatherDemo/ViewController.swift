//
//  ViewController.swift
//  WeatherDemo
//
//  Created by Nick on 01/05/2017.
//  Copyright © 2017 Nick Dowell. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var resultsTableView: UITableView!
    
    let weatherService = WeatherService()
    var response: WeatherService.Response?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.layoutMargins = UIEdgeInsetsMake(8, 8, self.tableViewTopConstraint.constant, 8)
        
        self.response = WeatherService.cachedResponse
        updateMapAnnotations(animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
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
        weatherService.fetchCities(near: coordinate) { (response) in
            DispatchQueue.main.async {
                if let response = response {
                    self.response = response
                    self.resultsTableView.reloadData()
                    self.updateMapAnnotations(animated: true)
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
    
    // MARK: -
    
    class MapAnnotation : NSObject, MKAnnotation {
        let item: WeatherService.Item
        
        init(_ item: WeatherService.Item) {
            self.item = item
        }
        
        public var coordinate: CLLocationCoordinate2D {
            get {
                return item.location.coordinate
            }
        }
        
        public var title: String? {
            get {
                return item.name;
            }
        }
    }
    
    func updateMapAnnotations(animated: Bool) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        if let items = self.response?.list {
            for item in items {
                self.mapView.addAnnotation(MapAnnotation(item))
            }
        }
        
        self.mapView.showAnnotations(self.mapView.annotations, animated: animated)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? MapAnnotation else {
            return nil
        }
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Item") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "Item")
        view.image = UIImage(named: annotation.item.iconCode)
        view.canShowCallout = true
        return view;
    }
}
