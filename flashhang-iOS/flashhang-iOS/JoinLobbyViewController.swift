import UIKit
import Firebase
import MapKit
import CoreLocation

class JoinLobbyViewController: FlashHangViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var idField: UITextField!
    let locationManager = CLLocationManager()
    var location: CLLocationCoordinate2D?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        idField.delegate = self
        setupLocationServices()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupLocationServices() {
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.location = locValue
    }
    
    func constructJsonMap() -> [String: Any] {
        return [
            "location": [location?.latitude, location?.longitude],
            "uid": Auth.auth().currentUser?.uid
        ]
    }
    
    func httpRequest(lobbyId: String) {
        let url = URL(string: backendUrl + "lobby/join/" + lobbyId)
        var request = URLRequest(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let jsonData = try? JSONSerialization.data(withJSONObject: constructJsonMap())
        request.httpBody = jsonData!
        let jsonString = String(data: jsonData!, encoding: .utf8)
        print(jsonString!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
        }
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "joinLobbyToLobbySegue" {
            let destination = segue.destination as! LobbyViewController
            destination.lobbyId = idField.text
        }
    }
    
    @IBAction func join(_ sender: Any) {
        let id = idField.text!
        if (id.count > 0) {
            httpRequest(lobbyId: id)
            performSegue(withIdentifier: "joinLobbyToLobbySegue", sender: nil)
        }
    }
    
}

