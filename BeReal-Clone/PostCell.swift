//
//  PostCell.swift
//  BeReal-Clone
//
//  Created by Derrick Ng on 3/22/23.
//

import UIKit
import Alamofire
import AlamofireImage

class PostCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var request: Alamofire.Request?
    private var imageDataRequest: DataRequest?
    
    func configure(with post: Post) {
        // TODO: Pt 1 - Configure Post Cell
        // Username
        if let user = post.user {
            nameLabel.text = user.username
        }

        // Image
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            self.request?.cancel() // Cancel the Alamofire request
            
            // Use AlamofireImage helper to fetch remote image from URL
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                
                switch response.result {
                case .success(let image):
                    // Set image view image with fetched image
                    self?.postImageView.image = image
                case .failure(let error):
                    print("❌ Error fetching image: \(error.localizedDescription)")
                    break
                }
            }
            self.request?.resume()
        }
        
        // Location
        locationLabel.text = post.location

        // Caption
        captionLabel.text = post.caption

        // Date
        if let date = post.createdAt {
            dateLabel.text = DateFormatter.postFormatter.string(from: date)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel image download and Reset image view image.
        postImageView.image = nil

        // Cancel image request.
        imageDataRequest?.cancel()
    }
    
    /*
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    */
}
