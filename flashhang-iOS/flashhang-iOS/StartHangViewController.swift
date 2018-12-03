import UIKit
import Firebase
import MapKit
import CoreLocation
/*
 Main screen consisting of a single "Flash Hang" button
 Sends a HTTP request to start or join a lobby
 */
class StartHangViewController: FlashHangViewController, CLLocationManagerDelegate {

    @IBOutlet var joinExistingButton: UIButton!
    @IBOutlet var hangButton: UIButton!
    
    var lobbyId = ""
    let locationManager = CLLocationManager()
    var location: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationServices()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupUI() {
        joinExistingButton.tintColor = colors["orange"]
    }
    
    //Location Services methods -------------------------------------------------------------
    
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
    
    //HTTP Request methods -------------------------------------------------------------
    
    func constructJsonMap(api: String) -> [String: Any] {
        if api == "lobby/start" {
            return [
                "uid": (Auth.auth().currentUser?.uid)!,
                "lobby_name": "hello"
            ]
        } else if api == "lobby/join" {
            return [
                "location": [location?.latitude, location?.longitude],
                "uid": Auth.auth().currentUser?.uid
            ]
        } else {
            return [:]
        }
    }
    
    func joinLobbyRequest() {
        let url = URL(string: backendUrl + "lobby/join/" + lobbyId)
        var request = URLRequest(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let jsonData = try? JSONSerialization.data(withJSONObject: constructJsonMap(api: "lobby/join"))
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
    
    func startLobbyRequest() {
        let url = URL(string: backendUrl + "lobby/start")
        var request = URLRequest(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let jsonData = try? JSONSerialization.data(withJSONObject: constructJsonMap(api: "lobby/start"))
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
            
            do {
                var responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                self.lobbyId = responseJson["lobby_id"]! as! String
            } catch let error {
                print("error")
            }
        }
        task.resume()
    }
    
    //IB Actions/Segues -------------------------------------------------------------
    
    @IBAction func joinExistingMeeting(_ sender: Any) {
        self.performSegue(withIdentifier: "startHangToJoinLobbySegue", sender: nil)
    }
    
    @IBAction func startHang(_ sender: Any) {
        self.startLobbyRequest()
        sleep(2)
        self.joinLobbyRequest()
        self.performSegue(withIdentifier: "startHangToShareLinkSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startHangToShareLinkSegue" {
            let destination = segue.destination as! ShareLinkViewController
            destination.lobbyId = self.lobbyId
        }
        if segue.identifier == "startHangToJoinLobbySegue" {
            let destination = segue.destination as! JoinLobbyViewController
        }
    }
    
    
}

