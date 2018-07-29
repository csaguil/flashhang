import UIKit
import Firebase

class LobbyViewController: FlashHangViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var inLobbyTableView: UITableView!
    @IBOutlet var startButton: UIButton!
    var refName: DatabaseReference!
    var refState: DatabaseReference!
    var choices: [[String: AnyObject]]?
    
    var lobbyId: String?
    
    var inLobby: [String] = []
    
    let tagNameLabel = 1001
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inLobbyTableView.delegate = self
        inLobbyTableView.dataSource = self
        setupFirebase()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleStateChangeToChoice() {
        performSegue(withIdentifier: "lobbyToVotingSegue", sender: nil)
    }
    
    func setupFirebase() {
        refName = Database.database().reference().child("lobbies/" + lobbyId! + "/current_members")
        let refNameHandle = refName.observe(.childAdded, with: { (snapshot) in
            let postDict = snapshot.value as? NSDictionary ?? [:]
            self.inLobby.append(postDict["name"] as! String)
            self.inLobbyTableView.reloadData()
        })
        
        refState = Database.database().reference().child("lobbies/" + lobbyId!)
        let refStateHandle = refState.observe(.value, with: { (snapshot) in
            let postDict = snapshot.value as? [String: AnyObject] ?? [:]
            print("-----------------------STATE--------------------------------")
            print(postDict["state"] as! String)
            if postDict["state"] as! String == "choice" {
                self.choices = postDict["choices"] as! [[String: AnyObject]]
                self.handleStateChangeToChoice()
            }
        })
    }
    
    func startSearch() {
        let url = URL(string: backendUrl + "lobby/start_search/" + self.lobbyId!)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        print(request)
        
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inLobby.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = (tableView.dequeueReusableCell(withIdentifier: "friendCell"))!
        let nameLabel = cell.viewWithTag(tagNameLabel) as! UILabel
        nameLabel.text = inLobby[indexPath.row]
        return cell
    }
    
    @IBAction func startHang(_ sender: Any) {
        startSearch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "lobbyToVotingSegue" {
            let destination = segue.destination as! VotingViewController
            destination.lobbyId = self.lobbyId
            destination.choices = self.choices
        }
    }
    
}

