import UIKit

class AddInterestsViewController: FlashHangViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    var allInterests = ["soccer", "hiking", "food trucks", "art galleries", "restuarants", "lectures", "movies"]
    var userInterests = [] as Array
    
    var tagInterestCellLabel = 1001
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allInterests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "interestCell")!
        let interestLabel = cell.viewWithTag(tagInterestCellLabel) as! UILabel
        interestLabel.text = allInterests[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        userInterests.append(allInterests[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let toDelete = allInterests[indexPath.row]
        var index: Int? = nil
        for i in 0...userInterests.count {
            if (userInterests[i] as! String == toDelete) {
                index = i
                break
            }
        }
        if index != nil {
            userInterests.remove(at: index!)
        }
    }
    
    @IBAction func next(_ sender: Any) {
        performSegue(withIdentifier: "addInterestsToStartHangSegue", sender: nil)
    }
}

