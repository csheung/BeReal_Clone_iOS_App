//
//  PostViewController.swift
//  BeReal-Clone
//
//  Created by Derrick Ng on 3/22/23.
//

import UIKit
import PhotosUI
import ParseSwift

class PostViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet weak var selectPhotoButton: UIButton!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!
    
    private var pickedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        // hide the image at first
        self.previewImageView.isHidden = true
        previewImageView.layer.borderColor = UIColor.white.cgColor
        selectPhotoButton.layer.borderColor = UIColor.white.cgColor
    }
    
    private func presentImagePicker() {
        // Create a configuration object
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())

        // Set the filter to only show images as options (i.e. no videos, etc.).
        config.filter = .images

        // Request the original file format. Fastest method as it avoids transcoding.
        config.preferredAssetRepresentationMode = .current

        // Only allow 1 image to be selected at a time.
        config.selectionLimit = 1

        // Instantiate a picker, passing in the configuration.
        let picker = PHPickerViewController(configuration: config)

        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self

        // Present the picker.
        present(picker, animated: true)
    }
    
    func presentCamera() {
        checkCameraAuthorizationStatusAndRequestIfNeeded { [weak self] granted in
            guard granted else {
                // Show an alert to inform the user that camera access is required
                print("Camera access is required!")
                return
            }

            DispatchQueue.main.async {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let imagePickerController = UIImagePickerController()
                    imagePickerController.delegate = self
                    imagePickerController.sourceType = .camera
                    self?.present(imagePickerController, animated: true, completion: nil)
                } else {
                    // Show an alert that the camera is not available
                    print("Camera is not available!")
                }
            }
        }
    }
    
    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        // If authorized, show photo picker, otherwise request authorization.
        // If authorization denied, show alert with option to go to settings to update authorization.
        if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
            // Request photo library access
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                switch status {
                case .authorized:
                    // The user authorized access to their photo library
                    // show picker (on main thread)
                    DispatchQueue.main.async {
                        self?.presentImagePicker()
                    }
                default:
                    // show settings alert (on main thread)
                    DispatchQueue.main.async {
                        // Helper method to show settings alert
                        self?.presentGoToSettingsAlert()
                    }
                }
            }
        } else {
            // Show photo picker
            presentImagePicker()
        }
    }
    
    @IBAction func openCameraButtonTapped(_ sender: UIBarButtonItem) {
        // Request permission to access the camera
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if !granted {
                    // Show an alert if access to the camera is not granted
                    let alert = UIAlertController(title: "Camera Access Denied", message: "Please grant access to the camera in Settings to use this feature.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            presentCamera()
        }
    }
    
    @IBAction func onPostTapped(_ sender: Any) {

        // Dismiss Keyboard
        view.endEditing(true)

        // Create and save Post
        // Unwrap optional pickedImage
        guard let image = pickedImage,
              // Create and compress image data (jpeg) from UIImage
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }

        // Create a Parse File by providing a name and passing in the image data
        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        // Create Post object
        var post = Post()

        // Set properties
        post.imageFile = imageFile
        post.caption = captionTextField.text

        // Set the user as the current user
        post.user = User.current

        // Save object in background (async)
        post.save { [weak self] result in

            // Switch to the main thread for any UI updates
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    print("✅ Post Saved! \(post)")

                    // Return to previous view controller
                    self?.navigationController?.popViewController(animated: true)

                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func onBackButtonTapped(_ sender: UIBarButtonItem) {
        print("🔙 Back to the previous view.")

        // Return to previous view controller
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onViewTapped(_ sender: Any) {
        // Dismiss keyboard
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

/// Add PHPickerViewController delegate and handle picked image.
extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Dismiss the picker
        picker.dismiss(animated: true)

        // Make sure we have a non-nil item provider
        guard let provider = results.first?.itemProvider,
           // Make sure the provider can load a UIImage
           provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

           // Make sure we can cast the returned object to a UIImage
           guard let image = object as? UIImage else {
              // ❌ Unable to cast to UIImage
               self?.showAlert()
               return
           }
            
            print("🌉 We have an image!")

           // Check for and handle any errors
           if let error = error {
               self?.showAlert(description: error.localizedDescription)
               return
           } else {

              // UI updates (like setting image on image view) should be done on main thread
              DispatchQueue.main.async { [weak self] in

                 // Set image on preview image view
                 self?.previewImageView.image = image

                 // Set image to use when saving post
                 self?.pickedImage = image
                  
                  // show the image on View Controller
                  self?.previewImageView.isHidden = false
              }
           }
        }
    }
}

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Get the selected image
        let image = info[.originalImage] as! UIImage

        // Do something with the image, such as displaying it in an image view
        previewImageView.image = image

        // Dismiss the image picker
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the image picker if the user cancels
        dismiss(animated: true, completion: nil)
    }
    
    func checkCameraAuthorizationStatusAndRequestIfNeeded(completion: @escaping (Bool) -> Void) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .restricted, .denied:
            completion(false)
        case .authorized:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
}

extension PostViewController {
    /// Presents an alert notifying user of photo library access requirement with an option to go to Settings in order to update status.
    func presentGoToSettingsAlert() {
        let alertController = UIAlertController (
            title: "Photo Access Required",
            message: "In order to post a photo to complete a task, we need access to your photo library. You can allow access in Settings",
            preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
//    /// Show an alert for the given error
//    private func showAlert(for error: Error? = nil) {
//        let alertController = UIAlertController(
//            title: "Oops...",
//            message: "\(error?.localizedDescription ?? "Please try again...")",
//            preferredStyle: .alert)
//
//        let action = UIAlertAction(title: "OK", style: .default)
//        alertController.addAction(action)
//
//        present(alertController, animated: true)
//    }
}
