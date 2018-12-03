import UIKit
import AgoraRtcEngineKit
import Firebase

/*
 Waiting screen with video chat, while backend computes the recommendations
 */
class VideoChatViewController: FlashHangViewController {
    
    @IBOutlet weak var localVideo: UIView!              // Tutorial Step 3
    @IBOutlet weak var remoteVideo: UIView!             // Tutorial Step 5
    
    var agoraKit: AgoraRtcEngineKit!
    var refState: DatabaseReference!
    
    var choices: [[String: AnyObject]]?
    var lobbyId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeAgoraEngine()     // Tutorial Step 1
        setupVideo()                // Tutorial Step 2
        setupLocalVideo()           // Tutorial Step 3
        joinChannel()               // Tutorial Step 4
        setupFirebase()
    }
    
    func setupFirebase() {
        refState = Database.database().reference().child("lobbies/" + lobbyId!)
        let refStateHandle = refState.observe(.value, with: { (snapshot) in
            let postDict = snapshot.value as? [String: AnyObject] ?? [:]
            print(postDict["state"] as! String)
            if postDict["state"] as! String == "choice" {
                self.choices = postDict["choices"] as! [[String: AnyObject]]
                self.performSegue(withIdentifier: "videoChatToVotingSegue", sender: nil)
            }
        })
    }
    
    //Agora methods -------------------------------------------------------------
    
    // Tutorial Step 1
    func initializeAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: "ac883fbf8483440e852e71ea25cafd3f", delegate: self)
    }
    
    // Tutorial Step 2
    func setupVideo() {
        agoraKit.enableVideo()  // Default mode is disableVideo
        agoraKit.setVideoProfile(.landscape360P, swapWidthAndHeight: false) // Default video profile is 360P
    }
    
    // Tutorial Step 3
    func setupLocalVideo() {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = localVideo
        videoCanvas.renderMode = .adaptive
        agoraKit.setupLocalVideo(videoCanvas)
    }
    
    // Tutorial Step 4
    func joinChannel() {
        agoraKit.joinChannel(byToken: nil, channelId: "demoChannel1", info:nil, uid:0) {[weak self] (sid, uid, elapsed) -> Void in
            // Join channel "demoChannel1"
            if let weakSelf = self {
                weakSelf.agoraKit.setEnableSpeakerphone(true)
                UIApplication.shared.isIdleTimerDisabled = true
            }
        }
    }
    
    //IBActions/Segues -------------------------------------------------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "videoChatToVotingSegue" {
            let destination = segue.destination as! VotingViewController
            destination.choices = self.choices
            destination.lobbyId = self.lobbyId
            agoraKit.leaveChannel(nil)
            remoteVideo.removeFromSuperview()
            localVideo.removeFromSuperview()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension VideoChatViewController: AgoraRtcEngineDelegate {
    // Tutorial Step 5
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = remoteVideo
        videoCanvas.renderMode = .adaptive
        agoraKit.setupRemoteVideo(videoCanvas)
    }
}

