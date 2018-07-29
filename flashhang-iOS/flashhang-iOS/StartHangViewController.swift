import UIKit

class StartHangViewController: FlashHangViewController {
    
    @IBOutlet var hangButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI() {
        hangButton.layer.cornerRadius = 0.5 * hangButton.bounds.size.width
    }
    
    @IBAction func startHang(_ sender: Any) {
        performSegue(withIdentifier: "startHangToShareLinkSegue", sender: nil)
    }
}

