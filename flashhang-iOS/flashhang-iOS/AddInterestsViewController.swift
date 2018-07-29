import UIKit
import Firebase

class AddInterestsViewController: FlashHangViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    var allInterests = ["escape games","amusement parks", "go karts", "museums", "cafes","bars", "karaoke", "zoos","maker spaces", "festivals","paintball", "mini golf", "bowling","spas"]
    var list_of_cats = ["escapegames","amusementparks", "gokarts", "museums", "cafes","bars", "karaoke", "zoos","makerspaces", "festivals","paintball", "mini_golf", "bowling","spas"]
    
    var readableToYelpMap: [String: String] = [
        "escape games": "escapegames",
        "amusement parks": "amusementparks",
        "go karts": "gokarts",
        "maker spaces": "makerspaces",
        "mini golf": "mini_golf"
    ]
    
    var userInterests: [String] = []
    
    var tagInterestCellLabel = 1001
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allInterests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "interestCell")!
        let interestLabel = cell.viewWithTag(tagInterestCellLabel) as! UILabel
        interestLabel.text = allInterests[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        userInterests.append(allInterests[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let toDelete = allInterests[indexPath.row]
        var index: Int? = nil
        for i in 0...userInterests.count {
            if (userInterests[i] as! String == toDelete) {
                index = i
                break
            }
        }
        if index != nil {
            userInterests.remove(at: index!)
        }
    }
    
    func constructJsonMap() -> [String: Any] {
        var preferences: [String] = []
        for interest in userInterests {
            if readableToYelpMap[interest] != nil {
                preferences.append(readableToYelpMap[interest]!)
            } else {
                preferences.append(interest)
            }
        }
        
        return [
            "uid": (Auth.auth().currentUser?.uid)!,
            "name": (Auth.auth().currentUser?.displayName)!,
            "preferences": preferences
        ]
    }
    
    @IBAction func next(_ sender: Any) {
        let url = URL(string: "https://2096f9d6.ngrok.io/signup")
        var request = URLRequest(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let jsonData = try? JSONSerialization.data(withJSONObject: constructJsonMap())
        print(jsonData == nil)
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
        
        performSegue(withIdentifier: "addInterestsToStartHangSegue", sender: nil)
    }
}

