//
//  MtaApi.swift
//  MaccabiTLV
//
//  Created by leonid angarov on 10/4/15.
//  Copyright © 2015 GoUFO. All rights reserved.
//

import Foundation
import SwiftyJSON
import SwiftyXMLParser
import Alamofire

typealias ServiceResponse = (JSON, NSError?) -> Void
typealias ServiceResponseXML = (XML.Accessor, NSError?) -> Void


class FM100Api : NSObject {
    
    let defaults = NSUserDefaults.init(suiteName: "group.fm100SharingGroup")
    static let keyPush = "keyPushToken110"
    
    static let shared = FM100Api()
    
    var stations:[Station] = [Station]()
    var programs:[[Program]] = [[Program]]()
    var video:VideoStream = VideoStream()
    var youtube:[VideoYouTube] = [VideoYouTube]()
    
    var isDataLoaded:Bool = false
    
    let infoURL = "http://digital.100fm.co.il/app/"
    
    func getInfo(onCompletion: (Bool) -> Void) {
        Alamofire.request(.GET, infoURL, parameters: [:]).responseJSON { response in
            if response.result.error != nil {
                onCompletion(false)
                return
            }
            if let data = response.result.value {
                let json = JSON(data)
                self.stations.removeAll()
                for (_, subJson) in json["stations"] {
                    let station:Station = Station(post: subJson)
                    self.stations.append(station)
                }
                
                let video:JSON = json["video"]
                
                self.video = VideoStream(post: video["stream"])
                
                self.youtube.removeAll()
                for (_, subJson) in video["archive"] {
                    let youtube:VideoYouTube = VideoYouTube(post: subJson)
                    self.youtube.append(youtube)
                }
                self.isDataLoaded = true
                onCompletion(true)
            } else {
                onCompletion(false)
            }
        }
    }
    
    func getSongXML(url:String, onCompletion: ServiceResponseXML) {
        Alamofire.request(.GET, url)
            .responseData { response in
                if response.result.error != nil {
                    onCompletion(XML.parse(response.data!), NSError.init(domain: "100fm.co.il", code: 500, userInfo: nil))
                } else if let data = response.data {
                    onCompletion(XML.parse(data), nil)
                } else {
                    onCompletion(XML.parse(response.data!), NSError.init(domain: "100fm.co.il", code: 500, userInfo: nil))
                }
        }
    }
    
    func getPrograms(onCompletion: (Bool) -> Void) {
        if self.programs.count > 0 {
            onCompletion(true)
            return
        }
        
        Alamofire.request(.GET, "http://www.100fm.co.il/smartphoneXML/programs.aspx")
            .responseData { response in
                if response.result.error != nil {
                    onCompletion(false)
                    return
                }
                if let data = response.data {
                    let xml = XML.parse(data)
                    
                    var index = -1
                    var day = ""
                    
                    self.programs.removeAll()
                    for element in xml["Programs", "Program"] {
                        let p:Program = Program(post: element)
                        
                        if( day != p.day ) {
                            index = index + 1
                            day = p.day
                            self.programs.append([])
                        }
                        self.programs[index].append( p )
                    }
                    onCompletion(true)
                } else {
                    onCompletion(false)
                }
        }
    }
    
    func setPushToken( val:String ) {
        setDefaultsValue(val, key: "keyPushToken110")
    }
    
    func getPushToken() -> String {
        return getDefaultsValue("keyPushToken110", fail: "")
    }
    
    func getDefaultsValue( key:String, fail:String ) -> String {
        if let str = defaults!.stringForKey(key) {
            return str
        }
        return fail
    }
    
    func setDefaultsValue( val:String, key:String ) {
        defaults!.setValue(val, forKey: key)
        defaults!.synchronize()
    }
    
    func setPushVal( val:String ) {
        setDefaultsValue(val, key: "keyPushValue")
    }
    func getPushVal() -> String {
        return getDefaultsValue("keyPushValue", fail: "")
    }
    
    func addFavChannel(slug:String) {
        let slugStr:String = getDefaultsValue("keySlugs", fail: ",")
        var slugs:[String] = slugStr.componentsSeparatedByString(",")
        
        print("slug ", slug, " slugStr ", slugStr)
        if slugs.count > 0 {
            if slugs[0] != slug {
                for i in 0..<slugs.count {
                    if( i < slugs.count ) {
                        if( slugs[i] == slug ) {
                            slugs.removeAtIndex(i)
                        }
                    }
                }
                slugs.insert(slug, atIndex: 0)
                if slugs.count > 4 {
                    slugs.removeAtIndex(slugs.count - 1)
                }
                setDefaultsValue(slugs.joinWithSeparator(","), key: "keySlugs")
            }
        }
    }
    func getLastFavChannelsSlug() -> String {
        let slugStr:String = getDefaultsValue("keySlugs", fail: ",")
        var slugs:[String] = slugStr.componentsSeparatedByString(",")
        return slugs[0]
    }
    /*func getFavChannels() -> [Station] {
     
     }*/
}
