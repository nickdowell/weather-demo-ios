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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomPanelView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let weatherService = WeatherService()
    var response: WeatherService.Response?
    var locationManager: CLLocationManager!
    var longPressCoordinate: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layoutMargins = UIEdgeInsetsMake(8, 8, self.bottomPanelView.frame.size.height, 8)
        self.mapView.layoutMargins = layoutMargins
        
        self.bottomPanelView.layer.shadowRadius = 5
        self.bottomPanelView.layer.shadowOpacity = 0.2
        self.bottomPanelView.layer.shadowColor = UIColor.black.cgColor
        
        self.response = WeatherService.cachedResponse
        updateMapAnnotations(animated: false)
        
        if self.response == nil {
            self.textField.text = "Reading"
            search(self.textField.text!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @IBAction func searchUserLocation(_ button: UIButton) {
        if self.locationManager == nil {
            self.locationManager = CLLocationManager()
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        }

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            let alertController = UIAlertController(
                title: NSLocalizedString("Cannot access location services", comment: ""),
                message: NSLocalizedString("To find the weather data near you, please open Settings and enable location access for this app", comment: ""),
                preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel)
            alertController.addAction(cancelAction)
            
            let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default, handler: { (action) in
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            alertController.addAction(settingsAction)
            
            self.present(alertController, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            requestLocation()
        }
    }
    
    func requestLocation() {
        self.activityIndicator.startAnimating()
        self.resultsTableView.isHidden = true
        self.textField.text = "Current Location"
        self.locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.mapView.showsUserLocation = true
        
        if let location = locations.first {
            fetchWeatherData(near: location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.activityIndicator.stopAnimating()
        self.resultsTableView.isHidden = false
        self.textField.text = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            search(text)
        }
        return true
    }
    
    func search(_ string: String) {
        self.textField.resignFirstResponder()
        CLGeocoder().geocodeAddressString(string) { (placemarks, error) in
            if let location = placemarks?.first?.location {
                self.fetchWeatherData(near: location.coordinate)
            }
        }
    }
    
    func fetchWeatherData(near coordinate: CLLocationCoordinate2D) {
        self.textField.resignFirstResponder()
        self.activityIndicator.startAnimating()
        self.resultsTableView.isHidden = true
        
        weatherService.fetchCities(near: coordinate) { (response) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                if let response = response {
                    self.response = response
                    self.resultsTableView.reloadData()
                    self.resultsTableView.isHidden = false
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
        
        var annotations: [MapAnnotation] = []
        if let items = self.response?.list {
            for item in items {
                annotations.append(MapAnnotation(item))
            }
        }

        self.mapView.addAnnotations(annotations)
        self.mapView.showAnnotations(annotations, animated: animated)
    }
    
    @IBAction func mapLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }

        self.becomeFirstResponder()
        
        let point = recognizer.location(in: self.mapView)
        self.longPressCoordinate = self.mapView.convert(point, toCoordinateFrom: nil)

        let menuController = UIMenuController.shared
        menuController.menuItems = [UIMenuItem(title: NSLocalizedString("Search", comment: ""), action: #selector(searchMapLocation))]
        menuController.setTargetRect(CGRect(origin: point, size: .zero), in: self.mapView)
        menuController.setMenuVisible(true, animated: true)
    }
    
    override var canBecomeFirstResponder: Bool { get { return true } }
    
    func searchMapLocation() {
        if let coordinate = self.longPressCoordinate {
            self.textField.text = String(format: "%.2f,%.2f", coordinate.latitude, coordinate.longitude)

            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                if let placemark = placemarks?.first {
                    self.textField.text = placemark.name
                }
            }

            fetchWeatherData(near: coordinate)
            self.longPressCoordinate = nil
        }
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
