//
//  ViewController.swift
//  TPushTester
//
//  Created by uwei on 5/24/16.
//  Copyright © 2016 Tencent. All rights reserved.
//

import Cocoa
import Security

let developerPushHost  = "gateway.sandbox.push.apple.com"
let distributePushHost = "gateway.push.apple.com"
let pushPort           = 2195
let deviceTokenLength  = 64

enum PushCertificateFileType:String {
    case PEM
    case P12
    case CER
}

class ViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet weak var apnsServerButton: NSButton!
    @IBOutlet weak var xgServerButton: NSButton!
    @IBOutlet weak var pushTokenTextField: NSTextField!

    @IBOutlet weak var pushMessageTextField: NSTextField!
    
    @IBOutlet weak var pushCertificatePathField: NSTextField!
    
    @IBOutlet weak var certificatePasswordTextField: NSTextField!
    
    @IBOutlet weak var certificateTitleLabel: NSTextField!
    @IBOutlet weak var certificatePasswordLabel: NSTextField!
    @IBOutlet weak var chooseCertificateButton: NSButton!
    @IBOutlet weak var developerHostButton: NSButton!
    @IBOutlet weak var distributionHostButton: NSButton!
    @IBOutlet weak var acccessIDLabel: NSTextField!
    @IBOutlet weak var accessIDTextField: NSTextField!
    @IBOutlet weak var secretKeyLabel: NSTextField!
    @IBOutlet weak var secretKeyTextFiled: NSTextField!
    @IBOutlet weak var managerQQLabel: NSTextField!
    @IBOutlet weak var managerQQTextField: NSTextField!
    
    
    
    private var socket:otSocket = nil
    private var context:SSLContext!
    private var keychain:SecKeychain?
    private var certificate:SecCertificateRef?
    private var identity:SecIdentity?
    private var pushDeviceToken:String = ""
    private var pushPayload:String     = ""
    private var pushCertificatePath    = ""
    private var pushCertificatePasswd  = ""
    private var pushHost               = ""
    // 1: distribution 2:developement
    private var apnsPushEnviromentIntValue:UInt = 2
    private var accessID = ""
    private var secretKey = ""
    
    // 2: distribution 1:developement
    private var xgPushEnviromentIntValue:UInt = 1
    private var xgPushManagerQQ = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        certificatePasswordTextField.hidden = true
        certificatePasswordLabel.hidden     = true
        if developerHostButton.state == 1 {
            pushHost = developerPushHost
        }
        if distributionHostButton.state == 1 {
            pushHost = distributePushHost
        }
        
        xgPushButtonDisplay()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        pushTokenTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        disconnect()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        exit(0)
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func uploadCertificate(sender: NSButton) {
        let panel = NSOpenPanel()
        panel.message = ""
        panel.prompt = "OK"
        panel.canChooseDirectories = true
        panel.canChooseFiles       = true
        panel.canCreateDirectories = false
        var path:NSString = ""
        let result = panel.runModal()
        if result == NSFileHandlingPanelOKButton {
            path = (panel.URL?.path)!
            
            // 判断是否选了文件
            var isDirectory:ObjCBool = false
            if NSFileManager.defaultManager().fileExistsAtPath(path as String, isDirectory: &isDirectory) {
                if Bool(isDirectory) {
                    return
                }
            }
            pushCertificatePathField.stringValue = path as String
            pushCertificatePath = path as String
            let type = PushCertificateFileType.init(rawValue: path.pathExtension.uppercaseString)!
            if apnsServerButton.state == NSOnState {
                    switch type {
                    case .PEM, .CER:
                        certificatePasswordTextField.hidden = true
                        certificatePasswordLabel.hidden     = true
                        break
                        
                    case .P12:
                        certificatePasswordTextField.hidden = false
                        certificatePasswordLabel.hidden     = false
                        break
                    }
            } else if xgServerButton.state == NSOnState {
                
                if accessID.characters.count == 0 {
                    showAlert("XG Push App acccess ID is incorrect")
                    return
                }
                
                if type == .PEM {
                    let certificateData = NSData.init(contentsOfFile: path as String)?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithCarriageReturn)
                    let ts = String(time(nil))
                    let type = String(xgPushEnviromentIntValue)
                    var sign  = "!#dataeye*&@!23ne5=^82"
                    let source = "dataeye" // defualt, juhe, cmstop,etc.
                    var paramsWithOutCertificate = ["app_id":accessID, "type":type, "qq":xgPushManagerQQ, "source":source, "ts":ts]
                    let p  = paramsWithOutCertificate.sort {$0.0 < $1.0}
                    for (k, v) in p {
                        sign = sign + k + "=" + v
                    }
                    let sig = md5(sign)
                    
                    paramsWithOutCertificate["sig"] = sig
                    paramsWithOutCertificate["certfile"] = certificateData!
                    let xgCertificateUploadURL = "http://api.xg.qq.com/certfile/update_apns_cert_pub"
                    let request = NSMutableURLRequest(URL: NSURL(string: xgCertificateUploadURL)!, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: 30)
                    request.HTTPMethod  = "POST"
                    var parameterString = ""
                    for (k, v) in paramsWithOutCertificate {
                        parameterString = parameterString + k + "=" + v + "&"
                    }
                    
                    parameterString = (parameterString as NSString).substringToIndex(parameterString.characters.count - 1)
                    
                    request.HTTPBody = parameterString.dataUsingEncoding(NSUTF8StringEncoding)
                    NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, response, error) in
                        if data != nil {
                            let returnData = try! NSJSONSerialization.JSONObjectWithData(data!, options:.MutableContainers)
                            var uploadResultInfo = ""
                            if (returnData["code"] as! NSNumber).integerValue == 0 {
                                uploadResultInfo = "Upload certificate OK!"
                            } else {
                                uploadResultInfo = returnData["info"] as! String
                            }
                            dispatch_async(dispatch_get_main_queue(), {
                                self.showAlert(uploadResultInfo)
                            })
                            
                        }
                    }).resume()
                    
                } else {
                    showAlert("Invalid certificate!")
                }
            }
        }
        
    }

    @IBAction func pushMessage(sender: NSButton) {
        if pushDeviceToken.characters.count != deviceTokenLength {
            showAlert("Token string occurs error!")
            return;
        }
        
        if pushMessageTextField.stringValue.characters.count == 0 {
            showAlert("Push message is empty!")
            return;
        }
        
        
        if apnsServerButton.state == NSOnState {
            //
        }
        
        if xgServerButton.state == NSOnState {
            if accessID.characters.count == 0 {
                showAlert("XG Push App acccess ID is incorrect")
                return
            }
            if secretKey.characters.count == 0 {
                showAlert("XG Push App secret key is incorrect")
                return
            }
            
            OCPush.pushFromXGServerWithDeviceToken(pushDeviceToken, accessID: accessID, secretKey: secretKey, payload:pushPayload, enviroment:String(apnsPushEnviromentIntValue), completion: { (message, code) in
                if code == 0 {
                    self.showAlert("XG Push a message done!")
                } else {
                    self.showAlert(message)
                }
            })
            return;
        }
        
        let fileExtension = (pushCertificatePath as NSString).pathExtension
        
        if let type = PushCertificateFileType.init(rawValue: fileExtension.uppercaseString)  {
            switch type {
            case .PEM:
                let pusher = OCPush()
                let result = pusher.pushMessageToDeviceToken(pushDeviceToken, payload: pushPayload, fromHost: (pushHost + ":" + String(pushPort)), withPEMFile: pushCertificatePath)
                if result < -2 {
                    showAlert("Network connection problem!")
                }
                if result == -1 || result == -2 {
                    showAlert("Load certificate error!")
                }
                
                if result == 0 {
                    showAlert("Certificate is OK,Push one message!")
                }
                
                break
                
            case .P12:
                let connectResult = connect()
                if connectResult == noErr {
                    let pushResult =  OCPush.pushToDeviceToken(pushDeviceToken, payload: pushPayload, context: context)
                    if pushResult == noErr {
                        let pemOutPath = (pushCertificatePath as NSString).stringByDeletingLastPathComponent
                        var pemType = ""
                        if developerHostButton.state == 1 {
                            pemType = "Developer"
                        }
                        if distributionHostButton.state == 1 {
                            pemType = "Distribution"
                        }
                        var shellString = "openssl pkcs12 -in " + pushCertificatePath + " -out " + pemOutPath + "/XG" + pemType + "PushCertificate.pem -nodes "
                        if !pushCertificatePasswd.isEmpty {
                            shellString = shellString + "-passin pass:" + pushCertificatePasswd
                        }
                        let result = shell(shellString)
                        
                        if result.exitCode == 0 {
                            showAlert("Certificate is OK,Push one message!\nCreate XG push certificate done!")
                        } else {
                            showAlert("Create XG push certificate failed!")
                        }
                        
                    } else {
                        showAlert("APNS Error!")
                    }
                } else {
                    showAlert("Can not connect to APNS")
                }

                break
                
            case .CER:
                let connectResult = connect()
                if connectResult == noErr {
                    OCPush.pushToDeviceToken(pushDeviceToken, payload: pushPayload, context: context)
                    showAlert("Certificate is OK,Push one message!")
                }
                break
            }
        }
    }
    
    @IBAction func chooseHost(sender: NSButton) {
        if sender == developerHostButton {
            pushHost = developerPushHost
            apnsPushEnviromentIntValue = 2
            xgPushEnviromentIntValue   = 1
        }
        if sender == distributionHostButton {
            pushHost = distributePushHost
            apnsPushEnviromentIntValue = 1
            xgPushEnviromentIntValue   = 2
        }
        
    }
    
    @IBAction func chooseServer(sender: NSButton) {
        pushCertificatePathField.stringValue = ""
        certificatePasswordLabel.hidden      = true
        certificatePasswordTextField.hidden  = true
        
        xgPushButtonDisplay()
    }
    
    // MARK:Private
    func connect() -> OSStatus {
        if self.pushCertificatePath.isEmpty {
            self.showAlert("You never choose a certificate!")
        }

        var peer:PeerSpec = PeerSpec(ipAddr: 0, port: 0)
        var result:OSStatus = MakeServerConnection(pushHost, Int32(pushPort), 1, &socket, &peer)
         NSLog("MakeServerConnection(): %d", result);
        if result != noErr {
            return result
        }
        
        
        // Create new SSL context.
        context = SSLCreateContext(kCFAllocatorDefault, SSLProtocolSide.ClientSide, SSLConnectionType.StreamType);
        
        // Set callback functions for SSL context.
        result = SSLSetIOFuncs(context, SocketRead, SocketWrite);
        NSLog("SSLSetIOFuncs(): %d", result);
        
        // Set SSL context connection.
        result = SSLSetConnection(context, socket);
        NSLog("SSLSetConnection(): %d", result);
        
        
        // Set server domain name.
        result = SSLSetPeerDomainName(context, pushHost, 30);
        NSLog("SSLSetPeerDomainName(): %d", result)
        
        
        let fileExtension = (pushCertificatePath as NSString).pathExtension
        let type = PushCertificateFileType.init(rawValue: fileExtension.uppercaseString)
        if type == PushCertificateFileType.CER {
            // Open keychain.
            result = SecKeychainCopyDefault(&keychain);
            NSLog("SecKeychainOpen(): %d", result);
        }
        

        
        let certificateData = NSData(contentsOfFile: pushCertificatePath);
        self.certificate = SecCertificateCreateWithData(kCFAllocatorDefault, certificateData!)
        if self.certificate == nil {
            return errSecCertificateCannotOperate
        }
        
        var certificates:CFArrayRef!
        if type == PushCertificateFileType.CER {
            // Create identity.
            result = SecIdentityCreateWithCertificate(keychain, certificate!, &identity);
            NSLog("SecIdentityCreateWithCertificate(): %d", result);
            var id:UnsafePointer<Void> = UnsafePointer(Unmanaged.passUnretained(identity!).toOpaque())
            
            // Set client certificate.
            certificates = CFArrayCreate(nil, &id, 1, nil)
        }
        if type == PushCertificateFileType.P12 {
            // Set client certificate.
            let identity = OCPush.getSecIdentityRefFromFile(pushCertificatePath, password: pushCertificatePasswd, statusCode: &result)
            
            if result == noErr {
                certificates = identity.takeRetainedValue()
            } else {
                if result == errSecPkcs12VerifyFailure {
                    showAlert("Incorrect password for PKCS12!")
                }
                if result == errSecDecode {
                    showAlert("Can not parse certificate!")
                }
                
                return result
            }
        }

        if (certificates == nil) {
            return result
        }
        
        result = SSLSetCertificate(context, certificates);
        NSLog("SSLSetCertificate(): %d", result);
        result = SSLHandshake(context);
        // Perform SSL handshake.
        while(result == errSSLWouldBlock) {
            result = SSLHandshake(context);
            NSLog("SSLHandshake(): %d", result);
        }
        
        return result
    }
    
    
    func disconnect() -> Void {
        if(self.certificate == nil) {
            return
        }
        // Define result variable.
        let result:OSStatus = SSLClose(context)
        NSLog("SSLClose(): %d", result)
        
        // Close connection to server.
        OCPush.closeSocket(socket)
    }
    func showAlert(message:String) -> Void {
        let alert = NSAlert()
        alert.messageText = message;
        alert.runModal()
        
    }
    
    // MARK: NSTextFiledDelegate
    override func controlTextDidChange(obj: NSNotification) {
        let textField:NSTextField = obj.object as! NSTextField
        if textField == pushMessageTextField {
            pushPayload = "{\"aps\":{\"alert\":\"" + (textField.stringValue) + "\",\"badge\":1}}"
        }
        if textField == pushTokenTextField {
            pushDeviceToken = textField.stringValue
        }
        
        if textField == certificatePasswordTextField {
            pushCertificatePasswd = textField.stringValue
        }
        
        if textField == accessIDTextField {
            accessID = textField.stringValue
        }
        if textField == secretKeyTextFiled {
            secretKey = textField.stringValue
        }
        if textField == managerQQTextField {
            xgPushManagerQQ = textField.stringValue
        }
        
    }
    
    
    
    func shell(input: String) -> (output: String, exitCode: Int32) {
        let arguments = input.characters.split { $0 == " " }.map(String.init)
        
        let task = NSTask()
        task.launchPath = "/usr/bin/env"
        task.arguments = arguments
        task.environment = [
            "LC_ALL" : "en_US.UTF-8",
            "HOME" : NSHomeDirectory()
        ]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        
        return (output, task.terminationStatus)
    }
    

    func xgPushButtonDisplay() -> Void {
        acccessIDLabel.hidden     = Bool.init(apnsServerButton.state)
        accessIDTextField.hidden  = Bool.init(apnsServerButton.state)
        secretKeyLabel.hidden     = Bool.init(apnsServerButton.state)
        secretKeyTextFiled.hidden = Bool.init(apnsServerButton.state)
        managerQQLabel.hidden     = Bool.init(apnsServerButton.state)
        managerQQTextField.hidden = Bool.init(apnsServerButton.state)
    }
    
    func md5(string: String) -> String {
        var digest:[UInt8] = [UInt8](count:Int(CC_MD5_DIGEST_LENGTH), repeatedValue:0)
        let data = (string as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        CC_MD5(data!.bytes, CC_LONG(data!.length), &digest)
        
        var digestHex = ""
        for index in 0..<Int(CC_MD5_DIGEST_LENGTH) {
            digestHex += String(format: "%02x", digest[index])
        }
        
        return digestHex
    }
    
}

