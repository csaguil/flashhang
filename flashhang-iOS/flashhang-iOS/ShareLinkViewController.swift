import UIKit

class ShareLinkViewController: FlashHangViewController, UITextFieldDelegate {
    
    @IBOutlet var urlTextField: UITextField!
    var lobbyId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.delegate = self
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        urlTextField.text = lobbyId
    }
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

