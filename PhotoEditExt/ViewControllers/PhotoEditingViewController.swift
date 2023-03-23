//
//  PhotoEditingViewController.swift
//  PhotoEditExt
//
//  Created by Yudiz Solutions Ltd on 14/03/23.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: EditImageVC, PHContentEditingController {

    var input: PHContentEditingInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
        
    // MARK: - PHContentEditingController
    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }
    
    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned true from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned false, the contentEditingInput has past edits "baked in".
        input = contentEditingInput
        dataImage = input?.displaySizeImage
        self.prepareUI()
    }
    
    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.
        DispatchQueue.global().async {
            // Create editing output from the editing input.
            if let input = self.input {
                let output = PHContentEditingOutput(contentEditingInput: input)
                if let resultImage = self.imgView.image {
                    if let renderedJPEGData = resultImage.jpegData(compressionQuality: 0.9)  {
                        try! renderedJPEGData.write(to: output.renderedContentURL)
                    }
                    do {
                        let archivedData = try NSKeyedArchiver.archivedData(withRootObject: "PhotoEditExt", requiringSecureCoding: true)
                        let adjustmentData = PHAdjustmentData(formatIdentifier: "com.app.PhotoEditingDemo.PhotoEditExt", formatVersion: "1.0", data: archivedData)
                        output.adjustmentData = adjustmentData
                    } catch {
                        print("Unable to archive image data")
                    }
                }
                completionHandler(output)
            }
        }
    }
    
    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }
    
    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }

}
