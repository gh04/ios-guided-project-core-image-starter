import UIKit
import CoreImage
import Photos
//some filters do not work with CIFilterBuiltins
import CoreImage.CIFilterBuiltins

class PhotoFilterViewController: UIViewController {

	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
	
    var originalImage: UIImage? {
        didSet {
            updateImage()
            guard let originalImage = originalImage else {
                scaledImage = nil
                return
            }
            
            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale
            
            scaledSize = CGSize(width: scaledSize.width*scale, height: scaledSize.height*scale)
            
            let scaledUIImage = originalImage.imageByScaling(toSize: scaledSize)
            
            scaledImage = scaledUIImage
        }
    }
    
    var scaledImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    
    private let context = CIContext()
    //Since it is declared here you can use it in other places as opposed to filtering in private func
    private let filter = CIFilter.colorControls()
    
	override func viewDidLoad() {
		super.viewDidLoad()
        
        let filter = CIFilter.gaussianBlur()
        ///without CoreImage.CIFilterBuiltins
        // let filter = CIFilter(name: "CIGaussianBlur")
        print(filter.attributes)
        
        originalImage = imageView.image
	}
    
    //MARK: - Helper Methods
    
    private func image(byFiltering image: UIImage) -> UIImage {
        let inputImage = CIImage(image: image)
        
        filter.inputImage = inputImage
        filter.saturation = saturationSlider.value
        filter.brightness = brightnessSlider.value
        filter.contrast = contrastSlider.value
        
        guard let outputImage = filter.outputImage else { return image }
        //extent - the whole image
        context.createCGImage(outputImage, from: outputImage.extent)
        
        guard let renderedCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return image }
        //
        return UIImage(cgImage: renderedCGImage)
        
    }
    
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }
    
    private func presentImagePickerController() {
        //If there are parent controls, work limits. Handle those blocks gracefullyt
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            //In production include an alert.
            print("The photo is not available.")
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
		// TODO: Save to photo library
        //Adding a break point allows you to see image in the
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
}


extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
