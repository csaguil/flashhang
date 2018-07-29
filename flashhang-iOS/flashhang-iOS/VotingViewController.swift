import UIKit
import Firebase
import AgoraRtcEngineKit

class VotingViewController: FlashHangViewController, UITableViewDelegate, UITableViewDataSource, AgoraRtcEngineDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var muteButton: UIButton!
    @IBOutlet var speakerButton: UIButton!
    var muteOn = false
    var speakerOn = false
    
    var lobbyId: String?
    var ref: DatabaseReference!
    var choices: [[String: AnyObject]]?
    var selectedChoiceIdx: Int?
    
    let tagActivityLabel = 1001
    let tagImage = 1002
    var agoraKit: AgoraRtcEngineKit!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFirebase()
        initializeAgoraEngine()
        setChannelProfile()
        joinChannel()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: "ac883fbf8483440e852e71ea25cafd3f", delegate: self)
    }
    
    func setChannelProfile() {
        agoraKit.setChannelProfile(.communication)
    }
    
    func joinChannel() {
        agoraKit.joinChannel(byToken: nil, channelId: "demoChannel1", info:nil, uid:0){[weak self] (sid, uid, elapsed) -> Void in
            // Join channel "demoChannel1"
        }
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
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
        cell.backgroundColor = colors["background"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choices!.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedChoiceIdx = indexPath.row
        self.performSegue(withIdentifier: "votingToActivityDetailSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! ActivityDetailViewController
        destination.choice = self.choices?[self.selectedChoiceIdx!]
    }
    
    @IBAction func toggleMute(_ sender: Any) {
        if muteOn { //text should read unmute
            muteButton.titleLabel?.text = "mute"
            agoraKit.muteLocalAudioStream(false)
        } else { //text should mute
            muteButton.titleLabel?.text = "unmute"
            agoraKit.muteLocalAudioStream(true)
        }
        muteOn = !muteOn
    }
    
    @IBAction func toggleSpeaker(_ sender: Any) {
        if speakerOn { //text should read disable
            speakerButton.titleLabel?.text = "Disable Speaker"
            agoraKit.setEnableSpeakerphone(true)
        } else { //text should read enable
            speakerButton.titleLabel?.text = "Enable Speaker"
            agoraKit.setEnableSpeakerphone(false)
        }
        speakerOn = !speakerOn
    }
}

