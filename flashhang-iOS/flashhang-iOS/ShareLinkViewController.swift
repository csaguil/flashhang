import UIKit

/*
 Screen which provides url to share with other users
 allowing them to join a given lobby
 
 lobby id is generated in StartHangViewController, then passed in
 to this controller during the segue
 */
class ShareLinkViewController: FlashHangViewController, UITextFieldDelegate {
    
    @IBOutlet var urlTextField: UITextField!
    var lobbyId = ""
    @IBOutlet var goToLobbyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.delegate = self
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupUI() {
        urlTextField.text = lobbyId
        goToLobbyButton.backgroundColor = colors["orange"]
        urlTextField.layer.borderWidth = 1.0
        urlTextField.layer.borderColor = colors["orange"]?.cgColor
    }
    
    //IB Actions/Segues -------------------------------------------------------------
    @IBAction func goToLobby(_ sender: Any) {
        performSegue(withIdentifier: "shareLinkToLobbySegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "shareLinkToLobbySegue" {
            let destination = segue.destination as! LobbyViewController
            destination.lobbyId = self.lobbyId
        }
    }
}

