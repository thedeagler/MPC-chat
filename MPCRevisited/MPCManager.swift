//
//  MPCManager.swift
//  MPCRevisited
//
//  Created by Stephen Wu on 2/23/17.
//  Copyright © 2017 Appcoda. All rights reserved.
//

import UIKit

import MultipeerConnectivity

protocol MPCManagerDelegate: class {
    func foundPeer()
    func lostPeer()
    func invitationWasReceived(fromPeer: String)
    func connectedWithPeer(peerID: MCPeerID)
}

class MPCManager: NSObject {
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    
    var foundPeers = [MCPeerID]()
    var invitationHandler: ((Bool, MCSession?) -> Void)!
    
    weak var delegate: MPCManagerDelegate?
    
    override init() {
        super.init()
        
        peer = getPeer()
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: Constants.serviceType)
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: Constants.serviceType)
        advertiser.delegate = self
    }
    
    func getPeer() -> MCPeerID {
        let displayName = Constants.displayName
        let defaults = UserDefaults.standard
        
        var peerID: MCPeerID
        
        // if peerID already exists, use that
        if let peerIDData = defaults.data(forKey: displayName) {
            peerID = NSKeyedUnarchiver.unarchiveObject(with: peerIDData) as! MCPeerID
            
        } else { // Otherwise, create a peerID and archive it
            peerID = MCPeerID(displayName: displayName)
            let peerIDData = NSKeyedArchiver.archivedData(withRootObject: peerID)
            defaults.set(peerIDData, forKey: displayName)
            defaults.synchronize()
        }
        
        return peerID
    }
    
    func sendData(dictionaryWithData dictionary: Dictionary<String, String>, toPeer targetPeer: MCPeerID) -> Bool {
        let dataToSend = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        let peersArray = [targetPeer]
        
        do {
            try session.send(dataToSend, toPeers: peersArray, with: .reliable)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

extension MPCManager: MCSessionDelegate {
    // Remote peer changed state.
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state{
        case MCSessionState.connected:
            print("Connected to session: \(session)")
            delegate?.connectedWithPeer(peerID: peerID)
            
        case MCSessionState.connecting:
            print("Connecting to session: \(session)")
            
        default:
            print("Did not connect to session: \(session)")
        }
    }
    
    
    // Received data from remote peer.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let dictionary: [String: AnyObject] = ["data": data as NSData, "fromPeer": peerID]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedMPCDataNotification"), object: dictionary)
    }
    
    
    // Received a byte stream from remote peer.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    
    // Start receiving a resource from remote peer.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    
    // Finished receiving a resource from remote peer and saved the content
    // in a temporary location - the app is responsible for moving the file
    // to a permanent location within its sandbox.
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
    }
}

extension MPCManager: MCNearbyServiceBrowserDelegate {
    // Found a nearby advertising peer.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("doowop \(peerID)")
        print("doowop \(foundPeers)")
        print("Found peer")
        if findPeer(peerID) == nil {
            print("new peer!")
            foundPeers.append(peerID)
            delegate?.foundPeer()
        }
    }
    
    
    // A nearby peer has stopped advertising.
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer!")
        if let index = findPeer(peerID) {
            print("removing peer")
            foundPeers.remove(at: index)
        }
        
        delegate?.lostPeer()
    }
    
    
    // Browsing did not start due to an error.
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print(error.localizedDescription)
    }
    
    private func findPeer(_ peerID: MCPeerID) -> Int? {
        for (index, aPeer) in foundPeers.enumerated() {
            if aPeer == peerID {
                return index
            }
        }
        
        return nil
    }
}

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
    // Incoming invitation request.  Call the invitationHandler block with YES
    // and a valid session to connect the inviting peer to the session.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Swift.Void) {
        self.invitationHandler = invitationHandler
        
        delegate?.invitationWasReceived(fromPeer: peerID.displayName)
    }
    
    
    // Advertising did not start due to an error.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print(error.localizedDescription)
    }
}




