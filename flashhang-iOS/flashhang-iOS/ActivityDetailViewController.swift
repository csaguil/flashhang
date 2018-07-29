import UIKit

class ActivityDetailViewController: FlashHangViewController {
    
    var choice: [String: AnyObject]?
    
    let tagName = 1001
    let tagImage = 1002
    let tagAddress = 1003
    let tagUrl = 1004
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func setupUI() {
        let nameLabel: UILabel = view.viewWithTag(tagName) as! UILabel
        let imageView: UIImageView = view.viewWithTag(tagImage) as! UIImageView
        let addressLabel: UILabel = view.viewWithTag(tagAddress) as! UILabel
        let urlField: UITextField = view.viewWithTag(tagUrl) as! UITextField
        
        if let name = self.choice?["name"] {
            nameLabel.text = name as! String
        }
        if let address = self.choice?["address"] {
            addressLabel.text = address as! String
        }
        if let urlString = self.choice?["url"] {
            urlField.text = urlString as! String
        }
        
        let photoArray = self.choice!["photos"] as! [String]
        let imageUrl = photoArray[0]
        
        if let url = URL(string: imageUrl) {
            let data = try? Data(contentsOf: url)
            imageView.image = UIImage(data: data!)
            imageView.contentMode = .scaleAspectFit
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

