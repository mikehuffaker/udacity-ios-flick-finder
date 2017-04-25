//
//  ViewController.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 11/5/15.
//  Modified by Mike Huffaker for Udacity Flick Find project lesson
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController
{
    
    // MARK: Properties
    
    var keyboardOnScreen = false
    
    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latLonSearchButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        phraseTextField.delegate = self
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Search Actions
    
    @IBAction func searchByPhrase(_ sender: AnyObject)
    {

        userDidTapView(self)
        setUIEnabled(false)
        
        if !phraseTextField.text!.isEmpty {
            photoTitleLabel.text = "Searching..."
            // TODO: Set necessary parameters!
            let methodParameters: [String: AnyObject] =
                [Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
                 Constants.FlickrParameterKeys.Text : phraseTextField.text as AnyObject,
                 Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL as AnyObject,
                 Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey as AnyObject,
                 Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod as AnyObject,
                 Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat as AnyObject,
                 Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback as AnyObject
                ]
            displayImageFromFlickrBySearch(methodParameters)
        }
        else
        {
            setUIEnabled(true)
            photoTitleLabel.text = "Phrase Empty."
        }
    }
    
    @IBAction func searchByLatLon(_ sender: AnyObject)
    {

        userDidTapView(self)
        setUIEnabled(false)
        
        if isTextFieldValid(latitudeTextField, forRange: Constants.Flickr.SearchLatRange) && isTextFieldValid(longitudeTextField, forRange: Constants.Flickr.SearchLonRange)
        {
            photoTitleLabel.text = "Searching..."
            // TODO: Set necessary parameters!
            let bboxText = bboxString()
            let methodParameters: [String: AnyObject] =
                [Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
                 Constants.FlickrParameterKeys.BoundingBox : bboxText as AnyObject,
                 Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL as AnyObject,
                 Constants.FlickrParameterKeys.APIKey : Constants.FlickrParameterValues.APIKey as AnyObject,
                 Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod as AnyObject,
                 Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat as AnyObject,
                 Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback as AnyObject
            ]
            displayImageFromFlickrBySearch(methodParameters)
        }
        else
        {
            setUIEnabled(true)
            photoTitleLabel.text = "Lat should be [-90, 90].\nLon should be [-180, 180]."
        }
    }
    
    // Construct and return location bounded box string
    private func bboxString() -> String
    {
        var bbox = ""
        if let tempLon = Double( longitudeTextField.text! ), let tempLat = Double( latitudeTextField.text! )
        {
            let roundedLon = round( ( tempLon * 100 ) / 100 )
            let roundedLat = round( ( tempLat * 100 ) / 100 )
        
            let minLon = max( ( roundedLon - Constants.Flickr.SearchBBoxHalfHeight ), Constants.Flickr.SearchLonRange.0 )
            let maxLon = min( ( roundedLon + Constants.Flickr.SearchBBoxHalfHeight ), Constants.Flickr.SearchLonRange.1 )
            let minLat = max( ( roundedLat - Constants.Flickr.SearchBBoxHalfWidth ), Constants.Flickr.SearchLatRange.0 )
            let maxLat = min( ( roundedLat + Constants.Flickr.SearchBBoxHalfWidth ), Constants.Flickr.SearchLatRange.1 )
        
            bbox.append ( String(minLon) )
            bbox.append ( "," )
            bbox.append ( String(minLat) )
            bbox.append ( "," )
            bbox.append ( String(maxLon) )
            bbox.append ( "," )
            bbox.append ( String(maxLat) )
        }
        else
        {
            bbox = "0,0,0,0"
        }

        return bbox
    }
    
    // Submit search URL to flickr and retrieve image data
    private func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject])
    {
        print(flickrURLFromParameters(methodParameters))
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest( url: flickrURLFromParameters(methodParameters) )
        
        print( "URL to send to Flickr is: \(request.url)" )
        
        // create network request
        let task = session.dataTask( with: request )
        {
            ( data, response, error ) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError( _ error: String )
            {
                print( error )
                print( "URL at time of error: \(request.url)" )
                performUIUpdatesOnMain
                {
                    self.setUIEnabled( true )
                    self.photoTitleLabel.text = "No photo returned. Try again."
                    self.photoImageView.image = nil
                }
            }
            
            // Check for error value returned
            guard ( error == nil ) else
            {
                displayError( "There was an error with the request: \(error?.localizedDescription)" )
                return
            }
            
            // Check for 2XX non-error response
            guard let statusCode = ( response as? HTTPURLResponse )?.statusCode,
                      statusCode >= 200 && statusCode <= 299
            else
            {
                displayError( "Your request returned a status code other than 2xx!" )
                return
            }
            
            // Check for data null value
            guard let data = data else
            {
                displayError( "No data was returned by the request!" )
                return
            }

            let parsedResult: [String:AnyObject]!
            do
            {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                
            } catch
            {
                displayError( "Could not parse the data as JSON: '\(data)'" )
                return
            }
            
            // Check for error from Flickr
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String,
                      stat == Constants.FlickrResponseValues.OKStatus
            else
            {
                displayError( "Flickr API returned an error. See error code and message in \(parsedResult)" )
                return
            }
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject]            else
            {
                displayError( "Cannot find key '\(Constants.FlickrResponseKeys.Photos)' \(parsedResult)" )
                return
            }
            
            guard let pageCount = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                displayError("Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
      
            print( "There were: \(pageCount) pages of photos returned")
            
            print( "Picking random page" )
            let maxPage = min( pageCount, 40 )
            let randomPage = Int(arc4random_uniform(UInt32((maxPage))))
            print( "Random page is: ", randomPage )
            
            self.displayImageFromFlickrBySearch( methodParameters, pageNumber: randomPage )
        }
    
        task.resume()
        
    }
    
    // Submit search URL to flickr and retrieve image data - by page number
    private func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], pageNumber: Int )
    {
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = pageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest( url: flickrURLFromParameters(methodParametersWithPageNumber) )
        
        print( "URL to send to Flickr is: \(request.url)" )
        
        // create network request
        let task = session.dataTask( with: request )
        {
            ( data, response, error ) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError( _ error: String )
            {
                print( error )
                print( "URL at time of error: \(request.url)" )
                performUIUpdatesOnMain
                {
                    self.setUIEnabled( true )
                    self.photoTitleLabel.text = "No photo returned. Try again."
                    self.photoImageView.image = nil
                }
            }
            
            // Check for error value returned
            guard ( error == nil ) else
            {
                displayError( "There was an error with the request: \(error?.localizedDescription)" )
                return
            }
            
            // Check for 2XX non-error response
            guard let statusCode = ( response as? HTTPURLResponse )?.statusCode,
                statusCode >= 200 && statusCode <= 299
                else
            {
                displayError( "Your request returned a status code other than 2xx!" )
                return
            }
            
            // Check for data null value
            guard let data = data else
            {
                displayError( "No data was returned by the request!" )
                return
            }
            
            let parsedResult: [String:AnyObject]!
            do
            {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                
            } catch
            {
                displayError( "Could not parse the data as JSON: '\(data)'" )
                return
            }
            
            print( "JSON Parsed Result: \(parsedResult)" )
            
            // Check for error from Flickr
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String,
                stat == Constants.FlickrResponseValues.OKStatus
                else
            {
                displayError( "Flickr API returned an error. See error code and message in \(parsedResult)" )
                return
            }
            
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject]            else
            {
                displayError( "Cannot find key '\(Constants.FlickrResponseKeys.Photos)' \(parsedResult)" )
                return
            }

            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]]            else
            {
                displayError( "Cannot find key '\(Constants.FlickrResponseKeys.Photo)' \(photosDictionary)" )
                return
            }
            
            if photosArray.count < 1
            {
                displayError( "No photos were found, search again" )
                return
            }
            else
            {
                print( "getting random index" )
                let randomPhotoIndex = Int(arc4random_uniform(UInt32((photosArray.count))))
                print( "random index is: ", randomPhotoIndex )
                let photoDictionaryRandom = photosArray[randomPhotoIndex] as [String:AnyObject]
                let photoTitle = photoDictionaryRandom[Constants.FlickrResponseKeys.Title] as? String
            
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = photoDictionaryRandom[Constants.FlickrResponseKeys.MediumURL] as? String else
                {
                    displayError("Cannot find key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoDictionaryRandom)")
                    return
                }
            
                // if an image exists at the url, set the image and title
                let imageURL = URL(string: imageUrlString)
                if let imageData = try? Data(contentsOf: imageURL!)
                {
                    performUIUpdatesOnMain
                    {
                        self.setUIEnabled(true)
                        self.photoImageView.image = UIImage(data: imageData)
                        self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
                    }
                }
                else
                {
                    displayError("Image does not exist at \(imageURL)")
                }
            }

        }
        
        task.resume()
    }

    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL
    {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters
        {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}

// MARK: - ViewController: UITextFieldDelegate

extension ViewController: UITextFieldDelegate
{
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(_ notification: Notification)
    {
        if !keyboardOnScreen
        {
            view.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification)
    {
        if keyboardOnScreen
        {
            view.frame.origin.y += keyboardHeight(notification)
        }
    }
    
    func keyboardDidShow(_ notification: Notification)
    {
        keyboardOnScreen = true
    }
    
    func keyboardDidHide(_ notification: Notification)
    {
        keyboardOnScreen = false
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat
    {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func resignIfFirstResponder(_ textField: UITextField)
    {
        if textField.isFirstResponder
        {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func userDidTapView(_ sender: AnyObject)
    {
        resignIfFirstResponder(phraseTextField)
        resignIfFirstResponder(latitudeTextField)
        resignIfFirstResponder(longitudeTextField)
    }
    
    // MARK: TextField Validation
    
    func isTextFieldValid(_ textField: UITextField, forRange: (Double, Double)) -> Bool
    {
        if let value = Double(textField.text!), !textField.text!.isEmpty
        {
            return isValueInRange(value, min: forRange.0, max: forRange.1)
        } else
        {
            return false
        }
    }
    
    func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool
    {
        return !(value < min || value > max)
    }
}

// MARK: - ViewController (Configure UI)

private extension ViewController
{
    
     func setUIEnabled(_ enabled: Bool)
     {
        photoTitleLabel.isEnabled = enabled
        phraseTextField.isEnabled = enabled
        latitudeTextField.isEnabled = enabled
        longitudeTextField.isEnabled = enabled
        phraseSearchButton.isEnabled = enabled
        latLonSearchButton.isEnabled = enabled
        
        // adjust search button alphas
        if enabled
        {
            phraseSearchButton.alpha = 1.0
            latLonSearchButton.alpha = 1.0
        }
        else
        {
            phraseSearchButton.alpha = 0.0
            latLonSearchButton.alpha = 0.0
        }
    }
}

// MARK: - ViewController (Notifications)

private extension ViewController
{
    
    func subscribeToNotification(_ notification: NSNotification.Name, selector: Selector)
    {
        NotificationCenter.default.addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    func unsubscribeFromAllNotifications()
    {
        NotificationCenter.default.removeObserver(self)
    }
}
