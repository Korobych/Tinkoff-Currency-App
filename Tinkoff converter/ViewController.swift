//
//  ViewController.swift
//  Tinkoff converter
//
//  Created by Sergey Korobin on 14.09.17.
//  Copyright © 2017 Korob. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{
    
    
    @IBOutlet weak var CurrencyLabel: UILabel!

    @IBOutlet weak var DateLabel: UILabel!
    @IBOutlet weak var LoadInd: UIActivityIndicatorView!
    
    @IBOutlet weak var CurrencyList_from: UIPickerView!
    
    @IBOutlet weak var CurrencyList_after: UIPickerView!
    
    @IBAction func RetryButton(_ sender: UIButton) {
        pre_request()
        self.CurrencyList_from.selectRow(0, inComponent: 0, animated: true)
        self.CurrencyList_after.selectRow(0, inComponent: 0, animated: true)
        self.CurrencyLabel.text = ""
    }
    var currencies = [String]()
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        if pickerView == CurrencyList_after{
//            return self.baseExept().count
//        }
        return currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        if pickerView == CurrencyList_after{
//            return self.baseExept()[row]
//        }
        
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == CurrencyList_from {
            self.CurrencyList_after.reloadAllComponents()
        }
        self.updateCurrentCurrency()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.CurrencyLabel.text = nil
        self.CurrencyList_from.dataSource = self
        self.CurrencyList_after.dataSource = self
        self.CurrencyList_from.delegate = self
        self.CurrencyList_after.delegate = self
        pre_request()
        
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func pre_request() {
        LoadInd.startAnimating()
        let url = URL(string: "https://api.fixer.io/latest")
        let datatask = URLSession.shared.dataTask(with: url!){
            (data, response, error) in
            
            if error == nil
            {
                if data != nil
                {
                    do
                    {
                        let json_cont = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                        if let rates = json_cont["rates"] as? NSDictionary
                        {
                            self.currencies.removeAll()
                            for (cur,_) in rates
                            {
                                self.currencies.append((cur as? String)!)
                            }
                            self.currencies.append("EUR")
                            self.currencies.sort()
                            print("Currencies are loaded ")
                        }
                        if let date = json_cont["date"] as? String
                        {
                            self.DateLabel.text = date
                        }
                    }
                    catch
                    {
                        
                    }
                }
            }
            else
            {
                print("Не могу обновить курсы!")
//                ошибка отсутствия данных выкидывается ALERT NET INETA
            }
            DispatchQueue.main.async {
                self.LoadInd.stopAnimating()
                self.LoadInd.hidesWhenStopped = true
                self.CurrencyList_after.reloadAllComponents()
                self.CurrencyList_from.reloadAllComponents()
            }
            
        }
        datatask.resume()
    }
    
    func requestCurrency(baseCurrency: String, parseHandler: @escaping (Data?, Error?) -> Void){
        let cur_url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let cur_dataTask = URLSession.shared.dataTask(with: cur_url){
            (dataRecieved, response, error) in
            parseHandler(dataRecieved, error)
        }
        cur_dataTask.resume()
        
    }
    
    func baseExept() -> [String] {
        var cur_mod = currencies
        if cur_mod.count != 0{
            cur_mod.remove(at: CurrencyList_from.selectedRow(inComponent: 0))
            return cur_mod
        }
        else{
            return currencies
        }
    }
    
    func parseCur(data: Data?, toCurrency: String) -> String{
        var str = ""
        
        do{
            let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String,Any>
            if let parsed_json = json{
                if let cur_rates = parsed_json?["rates"] as? Dictionary<String, Double>{
                    if let elem = cur_rates[toCurrency] {
                        str = String(format:"%.2f", elem)
                    }
                    else
                    {
                        str = "..."
                        //ALARM NO CURRENCY + одинаковая валюта
                    }
                }
                else
                {
                    str = "Can't find _rates_ in json"
                }
            }
            else
            {
                str = "JSON can't be parsed. No data available!"
                // ALARM NO DATA FOUND
            }
        }
        return str
    }
    
    func retrieveCurrency(baseCurrency: String, toCurrency: String, completion: @escaping(String) -> Void) {
        self.requestCurrency(baseCurrency: baseCurrency) { [weak self] (data, error) in
        var string = "No currency retrieved"
        
            if let currentError = error{
                string = currentError.localizedDescription
            }
            else{
                string = (self?.parseCur(data: data, toCurrency: toCurrency))!
            }
        completion(string)
       }
    }
    
    func updateCurrentCurrency() {
        self.LoadInd.startAnimating()
        let baseCurrencyIndex = self.CurrencyList_from.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.CurrencyList_after.selectedRow(inComponent: 0)
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currencies[toCurrencyIndex]
        
        self.retrieveCurrency(baseCurrency: baseCurrency, toCurrency: toCurrency) { [weak self] (val) in
            DispatchQueue.main.async(execute: {
                self?.CurrencyLabel.text = val
                self?.LoadInd.stopAnimating()
            })
        }
    }
    


}

