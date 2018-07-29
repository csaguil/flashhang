import UIKit

class ShareLinkViewController: FlashHangViewController, UITextFieldDelegate {
    
    @IBOutlet var urlTextField: UITextField!
    
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
        urlTextField.text = "bit.ly/32455"
    }
    @IBAction func goToLobby(_ sender: Any) {
        performSegue(withIdentifier: "shareLinkToLobbySegue", sender: nil)
    }
}

