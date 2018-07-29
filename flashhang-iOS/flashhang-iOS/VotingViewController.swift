import UIKit
import Firebase

class VotingViewController: FlashHangViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    var lobbyId: String?
    var ref: DatabaseReference!
    var choices: [[String: AnyObject]]?
    
    let tagActivityLabel = 1001
    let tagImage = 1002
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFirebase()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupFirebase() {
        ref = Database.database().reference().child("lobbies/" + lobbyId! + "/choices")
        let refHandle = ref.observe(.childAdded, with: { (snapshot) in
            let postDict = snapshot.value as? NSDictionary ?? [:]
//            self.inLobby.append(postDict["name"] as! String)
//            self.inLobbyTableView.reloadData()
        })
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "activityCell")!
        let data = choices![indexPath.row]
        let label: UILabel = cell.viewWithTag(1001) as! UILabel
        label.text = data["name"] as! String
        let imageView: UIImageView = cell.viewWithTag(1002) as! UIImageView
        let photoArray = data["photos"] as! [String]
        let imageUrl = photoArray[0]
        
        if let url = URL(string: imageUrl) {
            let data = try? Data(contentsOf: url)
            imageView.image = UIImage(data: data!)
            imageView.contentMode = .scaleAspectFit
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choices!.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
}

