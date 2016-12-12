//
//  CertificateUploader.swift
//  TPushTester
//
//  Created by uwei on 12/12/2016.
//  Copyright © 2016 Tencent. All rights reserved.
//

import Foundation

public class CertificaterUploader:NSObject {
    class func upload(path:String, accessID:String, xgPushEnviromentIntValue:UInt, xgPushManagerQQ:String, xgServerState:Int, completionHandler:(result:Bool, host:String?, info:String?) -> Void) -> Void {
        var xgHost:String = ""
        if xgServerState == 1 {
            xgHost = "testopenapi.xg.qq.com"
            
        } else {
            xgHost = "openapi.xg.qq.com"
        }
        completionHandler(result: true, host: xgHost, info: "OK")
        
        return
        
        
        
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
        let sig = CertificaterUploader.md5(sign)
        
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
                    var xgHost:String!
                    if xgServerState == 1 {
                        xgHost = "testopenapi.xg.qq.com"
                        
                    } else {
                        xgHost = "openapi.xg.qq.com"
                    }
                    completionHandler(result: true, host: xgHost, info: "OK")
                } else {
                    uploadResultInfo = returnData["info"] as! String
                    completionHandler(result: false, host: nil, info: uploadResultInfo)
                }
            }
        }).resume()
    }



class func md5(string: String) -> String {
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