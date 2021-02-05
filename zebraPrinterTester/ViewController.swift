//
//  ViewController.swift
//  zebraPrinterTester
//
//  Created by Fernando on 21/1/2021.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var printerListTable: UITableView!
    
    var connectedAccessories : [EAAccessory] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateConnectedAccessories()
    }
    
    @IBAction func refreshBtnTouchUp(_ sender: Any) {
        updateConnectedAccessories()
        printerListTable.reloadData()
    }
    
    private func updateConnectedAccessories(){
        connectedAccessories = EAAccessoryManager.shared().connectedAccessories
    }
}

extension ViewController : UITableViewDelegate{
    
}

extension ViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return connectedAccessories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        var cell : UITableViewCell!
        cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        
        let eaAccessory = connectedAccessories[indexPath.row]
        cell.textLabel?.text = eaAccessory.name + " " + eaAccessory.modelNumber + " " + eaAccessory.serialNumber
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.connectEaAccessory(eaAccessory: connectedAccessories[indexPath.row])
    }
}

extension ViewController{

    private func connectEaAccessory(eaAccessory : EAAccessory){
        if eaAccessory.modelNumber.hasPrefix("ZQ620"){

            //Note: Zebra SDK requires communication in background thread
            DispatchQueue.global(qos: .background).async {
                //Zebra SDK specific code -- Start
                var connection :  NSObjectProtocol & ZebraPrinterConnection //define variable that confronts to NSObjectProtocol & ZebraPrinterConnection
                connection = MfiBtPrinterConnection.init(serialNumber: eaAccessory.serialNumber)! //Call Zebra's SDK to init a BT Connection
                
                if connection.open(){
                    print ("Printer Connected")
                    do{
                        var printer : ZebraPrinter & NSObjectProtocol //define variable that confronts to NSObjectProtocol & ZebraPrinter
                        printer = try ZebraPrinterFactory.getInstance(connection)
                        
                        let printerLanguage = printer.getControlLanguage()
                        print ("Connected Printer uses the following language: \(printerLanguage)")
                        if printerLanguage == PRINTER_LANGUAGE_ZPL{
                            self.configureLabelSize(connection: connection)
                            self.sendZebraTestingString(connection: connection)
                        } else{
                            print ("Our program only support printer using ZPL language")
                        }
                        
                    }catch{
                        print ("Error occured: \(error.localizedDescription)")
                    }
                    
                }else{
                    print ("Failed to Connect to ZQ620 Printer")
                    
                }
                //Zebra SDK specific code -- End
            }
        }
    }
    
    private func sendStrToPrinter(_ strToSend: String, connection: ZebraPrinterConnection){
        let data = strToSend.data(using: .utf8)!
        var error : NSErrorPointer = nil
        connection.write(data, error: error)
    }
    private func configureLabelSize(connection: ZebraPrinterConnection){
        let strToSend = """
        ^XA
        ^PW408
        ^LT16
        ^XZ
        """
        sendStrToPrinter(strToSend, connection: connection)
    }
    private func sendZebraTestingString(connection: ZebraPrinterConnection){
        
        //strToSend it written in ZPL language
        let testingStr = "^XA^FO17,16^GB379,371,8^FS^FT65,255^A0N,135,134^FDTEST^FS^XZ"
        sendStrToPrinter(testingStr, connection: connection)
        
        //The first
        let testingLabelStr = """
        ^XA^BY2,2.:1,70
        ^LH10,10
        ^MD10
        ^CFF,,
        ^FO350,10^FDC^FS
        ^CFE,,
        ^FO266,10^FD[NS]^FS
        ^CFE,,
        ^FO10,10^FDANCA QM*^FS
        ^CFD,,
        ^FO10,35^FDClotted Blood in Plain Tube*^FS
        ^FO10,55^FD22/08/13^FS
        ^FO114,55^FD17:49^FS
        ^FO182,55^FDQMHSP1300181276^FS
        ^FO20,75^BCN,60,N,,,^FD>:QMHSP>51300181276>6^FS
        ^CFF,,
        ^FO10,140^FDA3215310^FS
        ^CFD,,
        ^FO242,150^FDIP/HOME/E1^FS
        ^FO10,170^FDPATIENT, 157167^FS
        ^FO10,190^FD^FS
        ^FO190,190^FD(      )^FS
        ^FO302,190^FDM/96y^FS
        ^IDOUTSTR01^FS
        ~DGOUTSTR01,00216,008,gU038K078M03L07L060301CI07L07JFEI07L06N07L06N07K0H6I01CI07
        K036JFEI07K03EH0CK07L06H0CK078K0H61C18I0F8K067IFCI0D8K0E61818I0HCJ03E61818H01HCJ
        07H63C18H0186K0H63718H0387K0I6198H0303K0C6E1D8H06018J0C780D8H0E01CJ0C7H01801CH0E
        I0186H01803I078H0186H01806I03EH030601F81CJ0FH0606H0703gJ0
        ^FO10,210^XGOUTSTR01,1,1^FS
        ^FO350,218^FD*^FS
        ^PQ0
        ^XZ-
        """
        sendStrToPrinter(testingLabelStr, connection: connection)
    }
}
