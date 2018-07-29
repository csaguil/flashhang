import UIKit
import Firebase

class StartHangViewController: FlashHangViewController {

    
    @IBOutlet var hangButton: UIButton!
    var lobbyId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        hangButton.layer.cornerRadius = 0.5 * hangButton.bounds.size.width
    }
    
    func constructJsonMap() -> [String: Any] {
        return [
            "uid": (Auth.auth().currentUser?.uid)!,
            "lobby_name": "hello"
        ]
    }
    
    @IBAction func startHang(_ sender: Any) {
        let url = URL(string: "https://2096f9d6.ngrok.io/lobby/start")
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
            
            do {
                var responseJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                print(responseJson["lobby_id"]! as! String)
                print("-------------------------------------------------------------------------------------")
                self.lobbyId = responseJson["lobby_id"]! as! String
            } catch let error {
                print("error")
            }
        }
        task.resume()
        self.performSegue(withIdentifier: "startHangToShareLinkSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "startHangToShareLinkSegue" {
            let destination = segue.destination as! ShareLinkViewController
            destination.lobbyUrl = "https://2096f9d6.ngrok.io/" + self.lobbyId
            print("2-------------------------------------------------------------------------------------")
            print(self.lobbyId)
        }
    }
}

