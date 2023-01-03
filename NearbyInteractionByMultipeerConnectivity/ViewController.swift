//
//  ViewController.swift
//  NearbyInteractionByMultipeerConnectivity
//
//  Created by AM2190 on 2021/11/17.
//

import UIKit
import MultipeerConnectivity
import NearbyInteraction

var r_for_ui: Double = 100
var offsetX: Double = 0
var offsetY: Double = 0

var istap:Int = 0

let label = UILabel()
//ちゃんとこの値が半径に反映されている

class ViewController: UIViewController {
    // MARK: - NearbyInteraction variables
    var niSession: NISession?
    var myTokenData: Data?
    
    // MARK: - MultipeerConnectivity variables
    var mcSession: MCSession?
    var mcAdvertiser: MCNearbyServiceAdvertiser?
    var mcBrowserViewController: MCBrowserViewController?
    let mcServiceType = "mizuno-uwb"
    let mcPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    // MARK: - CSV File instances
    var file: File!
    
    // MARK: - IBOutlet instances
    @IBOutlet weak var connectedDeviceNameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var directionXLabel: UILabel!
    @IBOutlet weak var directionYLabel: UILabel!
    @IBOutlet weak var directionZLabel: UILabel!
//    @IBOutlet weak var r_UI_Label: UILabel!
    
    //スライダー追加時の挙動
//    @IBOutlet weak var label: UILabel!

    var drawView: DrawView?
 
//    @IBAction func sliderChanged(_ sender: UISlider) {
//        label.text = String(sender.value * 100)
//        r_for_ui = Double(sender.value) * 100
//        //ラベルに値を流し込む
//        print(r_for_ui)
//
//        // NOTE(mactkg): drawViewに対して、再描画を依頼すればOK。
//        self.drawView?.setNeedsDisplay()
//    }
    
    
    // MARK: - UI lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let drawView = DrawView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width
                                              , height: view.frame.size.height))
        //これがSubViewの大きさ
        
//        let label = UILabel()
//        label.frame = CGRect(x:200, y:400, width:160, height:30)
//        label.text = "metaBox"
//        self.view.addSubview(label)
        
        self.drawView = drawView // 作ったViewは、ViewControllerが持っておく
        // NOTE(mactkg): ここでViewController.viewにdrawViewが渡っているので、もう追加はいらない
        // NOTE(mactkg): もしsubViewから取り除きたいときは、`self.drawView?.removeFromSuperview()` になる。
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(printStack))
        drawView.addGestureRecognizer(tapGestureRecognizer)
        
        
        self.view.addSubview(drawView)

        


        }
    
    @objc private func printStack() {
            print("stack")
            istap = 1
        }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)           
        
        if niSession != nil {
            return
        }
        setupNearbyInteraction()
        setupMultipeerConnectivity()
        
        file = File.shared
    }
    
    // MARK: - Initial setting
    func setupNearbyInteraction() {
        // Check if Nearby Interaction is supported.
        guard NISession.isSupported else {
            print("This device doesn't support Nearby Interaction.")
            return
        }
        
        // Set the NISession.
        niSession = NISession()
        niSession?.delegate = self
        
        // Create a token and change Data type.
        guard let token = niSession?.discoveryToken else {
            return
        }
        myTokenData = try! NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    }
    
    func setupMultipeerConnectivity() {
        // Set the MCSession for the advertiser.
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: mcPeerID, discoveryInfo: nil, serviceType: mcServiceType)
        mcAdvertiser?.delegate = self
        mcAdvertiser?.startAdvertisingPeer()
        
        // Set the MCSession for the browser.
        mcSession = MCSession(peer: mcPeerID)
        mcSession?.delegate = self
        mcBrowserViewController = MCBrowserViewController(serviceType: mcServiceType, session: mcSession!)
        mcBrowserViewController?.delegate = self
        present(mcBrowserViewController!, animated: true)
    }
    
}

// MARK: - NISessionDelegate
extension ViewController: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        var stringData = ""
        // The session runs with one accessory.
        guard let accessory = nearbyObjects.first else { return }

        if let distance = accessory.distance {
            distanceLabel.text = distance.description
            stringData += distance.description
            
            let doubleDistance = Double(distanceLabel.text!)
            r_for_ui = doubleDistance!
            
            if r_for_ui > 1{
                r_for_ui = 1
            }
            
            
//            r_UI_Label.text = r_for_ui.description
//            r_for_uiに、距離のデータを代入
            drawView?.setNeedsDisplay()

        }else {
            distanceLabel.text = "-"
//            r_UI_Label.text = "-"

        }
        stringData += ","
        
        
        if let direction = accessory.direction {
            directionXLabel.text = direction.x.description
            directionYLabel.text = direction.y.description
            directionZLabel.text = direction.z.description
            
            //オフセットの処理
            let DoffsetX = Double(directionXLabel.text!)
            let DoffsetY = Double(directionYLabel.text!)
            offsetX = DoffsetX!
            offsetY = DoffsetY!
            
            stringData += direction.x.description + ","
            stringData += direction.y.description + ","
            stringData += direction.z.description
        }else {
            directionXLabel.text = "-"
            directionYLabel.text = "-"
            directionZLabel.text = "-"
        }
        
        stringData += "\n"
        file.addDataToFile(rowString: stringData)
        
    }
    //ここに処理を書き込めば動くのではないか…？？
//    こっちも動いている
    
    
    class DrawView: UIView {
     
        override init(frame: CGRect) {
            super.init(frame: frame);
            self.backgroundColor = UIColor.clear;
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        
        override func draw(_ rect: CGRect) {
            // ここにUIBezierPathを記述する
            //隠す用のやつ
            let rectangle = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 350, height: 750))
            // 内側の色
            UIColor(red: 1, green: 1, blue: 1, alpha: 1).setFill()
            // 内側を塗りつぶす
            rectangle.fill()
            

            // UIImage インスタンスの生成
            let image1:UIImage = UIImage(named:"lv1")!
            let image2:UIImage = UIImage(named:"lv2")!
            let image3:UIImage = UIImage(named:"lv3")!
            let image4:UIImage = UIImage(named:"lv4")!
            
            // UIImageView 初期化
            let imageView = UIImageView(image:image1)
            let imageView2 = UIImageView(image:image2)
            let imageView3 = UIImageView(image:image3)
            let imageView4 = UIImageView(image:image4)
            
            // スクリーンの縦横サイズを取得
            let screenWidth:CGFloat = frame.size.width
            let screenHeight:CGFloat = frame.size.height
            
            // 画像の縦横サイズを取得
            let imgWidth:CGFloat = image1.size.width
            let imgHeight:CGFloat = image1.size.height
            
            // 画像サイズをスクリーン幅に合わせる
            let scale:CGFloat = screenWidth / imgWidth
            let rect:CGRect =
                CGRect(x:0, y:0, width:imgWidth*scale, height:imgHeight*scale)
            
            // ImageView frame をCGRectで作った矩形に合わせる
            imageView.frame = rect;
            imageView2.frame = rect;
            imageView3.frame = rect;
            imageView4.frame = rect;
            
            // 画像の中心を画面の中心に設定
            imageView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
            imageView2.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
            imageView3.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
            imageView4.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
            
            
            // UIImageViewのインスタンスをビューに追加
            
            if r_for_ui<1 {
                self.addSubview(imageView)
            }else if 1<=r_for_ui && r_for_ui<2 {
                self.addSubview(imageView2)
            }else if 2<=r_for_ui && r_for_ui<3 {
                self.addSubview(imageView3)
            }else{
                self.addSubview(imageView4)
            }
            
        }


    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    }
}

// MARK: - MCSessionDelegate
extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            
            do {
                try session.send(myTokenData!, toPeers: session.connectedPeers, with: .reliable)

            } catch {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self.mcBrowserViewController?.dismiss(animated: true, completion: nil)
                self.connectedDeviceNameLabel.text = peerID.displayName
            }
            
        default:
            print("MCSession state is \(state)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        guard let peerDiscoverToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            print("Failed to decode data.")
            return }
        
        let config = NINearbyPeerConfiguration(peerToken: peerDiscoverToken)
        niSession?.run(config)
        
        file.createFile(connectedDeviceName: peerID.displayName)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
}

// MARK: - MCBrowserViewControllerDelegate
extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
    }
    
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        return true
    }
}
