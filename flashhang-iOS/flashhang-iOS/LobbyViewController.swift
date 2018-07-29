import UIKit

class LobbyViewController: FlashHangViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var joiningTableView: UITableView!
    @IBOutlet var inLobbyTableView: UITableView!
    @IBOutlet var startButton: UIButton!
    
    var joining = ["Sajana W.", "Omid A."]
    var inLobby = ["Robert E.", "Cristian S.", "Ryan A."]
    
    let tagNameLabel = 1001
    
    override func viewDidLoad() {
        super.viewDidLoad()
        joiningTableView.delegate = self
        joiningTableView.dataSource = self
        inLobbyTableView.delegate = self
        inLobbyTableView.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == joiningTableView {
            print("joining")
            return joining.count
        } else if tableView == inLobbyTableView {
            print("in Lobby")
            return inLobby.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = (tableView.dequeueReusableCell(withIdentifier: "friendCell"))!
        let nameLabel = cell.viewWithTag(tagNameLabel) as! UILabel
        if (tableView == joiningTableView) {
            nameLabel.text = joining[indexPath.row]
            
        } else if (tableView == inLobbyTableView) {
            nameLabel.text = inLobby[indexPath.row]
            
        }
        return cell
    }
    
    @IBAction func startHang(_ sender: Any) {
        performSegue(withIdentifier: "lobbyToVotingSegue", sender: nil)
    }
    
    
}

