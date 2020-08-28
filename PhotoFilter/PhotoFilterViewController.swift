import UIKit
import CoreImage
import Photos
//some filters do not work with CIFilterBuiltins
import CoreImage.CIFilterBuiltins

class PhotoFilterViewController: UIViewController {

    
    private let context = CIContext(options: nil)
       //Since it is declared here you can use it in other places as opposed to filtering in private func
       private let colorControlsFilter = CIFilter.colorControls()
       private let blurFilter = CIFilter.gaussianBlur()
    
	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var blurSlider: UISlider!
	
    var originalImage: UIImage? {
        didSet {
            // We want to scale down the image to make it easier to filter until the user is ready to save the image.
            updateImage()
            guard let originalImage = originalImage else {
                scaledImage = nil
                return
            }
            // The size of the imageView
            // height and width of the image view
            var scaledSize = imageView.bounds.size
            // 1, 2, or 3
            //resolution
            let scale: CGFloat = UIScreen.main.scale
            
            scaledSize = CGSize(width: scaledSize.width*scale, height: scaledSize.height*scale)
            
            // 'imageByScaling' is coming from the UIImage+scaling.swift
            guard let scaledUIImage = originalImage.imageByScaling(toSize: scaledSize) else {
//                scaledImage = nil
                return
            }
            
            scaledImage = CIImage(image: scaledUIImage)
        }
    }
    
    var scaledImage: CIImage? {
        didSet {
            updateImage()
        }
    }
    
   
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
//        let filter = CIFilter.gaussianBlur()
        ///without CoreImage.CIFilterBuiltins
        // let filter = CIFilter(name: "CIGaussianBlur")
//        print(filter.attributes)
        
        originalImage = imageView.image
	}
    

    
    //MARK: - Helper Methods
    

    private func image(byFiltering inputImage: CIImage) -> UIImage? {

        
        colorControlsFilter.inputImage = inputImage
        colorControlsFilter.saturation = saturationSlider.value
        colorControlsFilter.brightness = brightnessSlider.value
        colorControlsFilter.contrast = contrastSlider.value
        //clamping - repeating the colors to infinity so it not only blurring from the edges, making them transparent.
        blurFilter.inputImage = colorControlsFilter.outputImage?.clampedToExtent()
        blurFilter.radius = blurSlider.value

        guard let outputImage = blurFilter.outputImage else { return originalImage }
//        extent - the whole image
//using the origianl imagel
        guard let renderedCGIImage = context.createCGImage(outputImage, from: inputImage.extent) else { return originalImage }
        //
        return UIImage(cgImage: renderedCGIImage)

    }
    
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }
    
    private func presentImagePickerController() {
        //If there are parent controls, work limits. Handle those blocks gracefully
        // Make sure the photo library is available to use in the first place
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            //In production include an alert.
            NSLog("The photo is not available.")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
        
    }
	
	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
    presentImagePickerController()
	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {

        //Adding a break point allows you to see image in the
        //.flattened helper method to correctly orient a photo
        guard let originalImage = originalImage?.flattened, let ciImage = CIImage(image: originalImage) else { return }
        
        guard let filteredImage = image(byFiltering: ciImage) else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: filteredImage)
        }) { (success, error) in
            if let error = error {
               print("Error saving photo: \(error)")
//                NSLog("%@", error)
                return
            }
            //Present an alert to the user saying that the image was successfully saved
            
            DispatchQueue.main.async {
                self.presentSuccesfulSaveAlert()
            }
        }
	}
	
    private func presentSuccesfulSaveAlert() {
        let alert = UIAlertController(title: "Photo Saved!", message: "The photo has been saved to your Photo Library!", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        //present here
        present(alert, animated: true, completion: nil)
    }

	// MARK: Slider events
	
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        updateImage()
	}
    
    @IBAction func blurChanged(_ sender: Any) {
        updateImage()
    }
}


extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        //dimissing
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
