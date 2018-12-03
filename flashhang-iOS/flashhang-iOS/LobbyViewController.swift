import UIKit
import Firebase

/*
 Waiting screen to display which users are in the lobby
 Listens for firebase notifications of new users joining
 */
class LobbyViewController: FlashHangViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var inLobbyTableView: UITableView!
    @IBOutlet var startButton: UIButton!
    var refName: DatabaseReference!
    var refState: DatabaseReference!
    
    var lobbyId: String?
    var inLobby: [String] = []
    
    let tagNameLabel = 1001
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inLobbyTableView.delegate = self
        inLobbyTableView.dataSource = self
        setupFirebase()
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupUI() {
        startButton.backgroundColor = colors["orange"]
    }
    
    //HTTP Request/Firebase methods -------------------------------------------------------------
    
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
            print(postDict["state"] as! String)
            if postDict["state"] as! String == "started" {
                self.performSegue(withIdentifier: "lobbyToVideoChatSegue", sender: nil)
            }
        })
    }
    
    func startSearch() {
        let url = URL(string: backendUrl + "lobby/start_search/" + self.lobbyId!)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // check for fundamental networking error
            guard let data = data, error == nil else {
                print("error=\(error)")
                return
            }
            
            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
            }
            
            let responseString = String(data: data, encoding: .utf8)
        }
        task.resume()
    }
    
    //Table View Methods -------------------------------------------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inLobby.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = (tableView.dequeueReusableCell(withIdentifier: "friendCell"))!
        let nameLabel = cell.viewWithTag(tagNameLabel) as! UILabel
        nameLabel.text = inLobby[indexPath.row]
        cell.backgroundColor = UIColor.clear
        return cell
    }
    
    //IB Actions/Segues -------------------------------------------------------------
    
    @IBAction func startHang(_ sender: Any) {
        startSearch()
        self.performSegue(withIdentifier: "lobbyToVideoChatSegue", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "lobbyToVotingSegue" {
            let destination = segue.destination as! VotingViewController
            destination.lobbyId = self.lobbyId
            //destination.choices = self.choices
        } else if (segue.identifier == "lobbyToVideoChatSegue") {
            let destination = segue.destination as! VideoChatViewController
            destination.lobbyId = self.lobbyId
        }
    }
}

