//
//  ViewController.swift
//  Tinkoff converter
//
//  Created by Sergey Korobin on 14.09.17.
//  Copyright © 2017 Korob. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate{
    
    // Alerts
    let internetFailAlert = UIAlertController(title: "Обновление данных", message: "Отсутствует подключение к сети.", preferredStyle: UIAlertControllerStyle.alert)
    let dataErrorAlert = UIAlertController(title: "Ошибка", message: "Данных валюты не найдено!", preferredStyle: UIAlertControllerStyle.alert)
    
    // Outlets
    @IBOutlet weak var CurrencyLabel: UILabel!

    @IBOutlet weak var DateLabel: UILabel!
    
    @IBOutlet weak var WelcomeLabel: UILabel!
    @IBOutlet weak var LoadInd: UIActivityIndicatorView!
    
    @IBOutlet weak var DataReadyLabel: UILabel!
    @IBOutlet weak var CurrencyList_from: UIPickerView!
    
    @IBOutlet weak var CurrencyList_after: UIPickerView!
    
    @IBOutlet weak var NumberValue: UITextField!
    @IBOutlet weak var ValueTo: UITextField!
    @IBOutlet weak var NoInternetConnectionImage: UIImageView!
    
    @IBOutlet weak var ChangeRatesOutlet: UIButton!
    @IBAction func RetryButton(_ sender: UIButton) {
        pre_request()
        if flag{
             DispatchQueue.main.async {
                self.NumberValue.text = ""
                self.ValueTo.text = ""
            }
        }
    }
    // ++ добавлен функционал замены валют местами (меняются и значения в блоках подсчета)
    @IBAction func ChangeRates(_ sender: Any) {
        var rightValue = self.CurrencyList_after.selectedRow(inComponent: 0)
        var leftValue = self.CurrencyList_from.selectedRow(inComponent: 0)
        self.CurrencyList_from.selectRow(rightValue, inComponent: 0, animated: true)
        self.CurrencyList_after.selectRow(leftValue, inComponent: 0, animated: true)
        var textFieldLeftData = self.NumberValue.text
        var textFieldRightData = Double(self.ValueTo.text!)
        var clone = Double(textFieldLeftData!)
        DispatchQueue.main.async {
            self.NumberValue.text = String(format:"%.3f", textFieldRightData!)
            self.ValueTo.text = String(format:"%.3f", clone!)
        }
        updateCurrentCurrency()
    }
    var currencies = [String]()
    var flag: Bool = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {

        return currencies.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return currencies[row]
    }
    // функционал изолирования одинаковых положений валют (универсален)
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            self.CurrencyList_after.reloadAllComponents()
            if self.CurrencyList_from.selectedRow(inComponent: 0) == self.CurrencyList_after.selectedRow(inComponent: 0){
                if row == 0{
                    self.CurrencyList_after.selectRow(row + 1, inComponent: 0, animated: true)
                }
                else if self.currencies.count - row == 1{
                    self.CurrencyList_after.selectRow(row - 1, inComponent: 0, animated: true)
                }else{
                    self.CurrencyList_after.selectRow(row + 1, inComponent: 0, animated: true)
                }
            }
            self.updateCurrentCurrency()
    }
    
    // основные настройки вьюшки
    override func viewDidLoad() {
        super.viewDidLoad()
        self.CurrencyList_from.dataSource = self
        self.CurrencyList_after.dataSource = self
        self.CurrencyList_from.delegate = self
        self.CurrencyList_after.delegate = self
        self.NumberValue.delegate = self
        self.ValueTo.delegate = self
        self.LoadInd.hidesWhenStopped = true
        self.NumberValue.textAlignment = .center
        self.NumberValue.textColor = UIColor.lightGray
        self.NumberValue.font = UIFont(name: "Futura-Medium", size: 18)
        self.NumberValue.text = ""
        self.NumberValue.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.ValueTo.textAlignment = .center
        self.ValueTo.textColor = UIColor.lightGray
        self.ValueTo.font = UIFont(name: "Futura-Medium", size: 18)
        self.ValueTo.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.internetFailAlert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
        self.dataErrorAlert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
        pre_request()

        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // ++ логика для добавленных блоков подчетов, работает как слева направо, так и наоборот
    func textFieldDidChange(_ textField: UITextField) {
        if self.CurrencyLabel.text != "" {
            var currency_val = Double(self.CurrencyLabel.text!)
            var number_l = Double(self.NumberValue.text!)
            var number_r = Double(self.ValueTo.text!)
            if textField == NumberValue && textField.text != ""{
                DispatchQueue.main.async {
                    self.ValueTo.text = String(format:"%.3f", currency_val! * number_l!)
                }
            } else if textField == ValueTo && textField.text != ""
            {
                DispatchQueue.main.async {
                    self.NumberValue.text = String(format:"%.3f", number_r! / currency_val!)
                }
            }
        }
    }
    
    // при переключении правого Picker'a пересчет значений правого блока в интересующую валюту
    func updateRightTextField() {
            var currency_val_cur = Double(self.CurrencyLabel.text!)
            var number_l_cur = Double(self.NumberValue.text!)
            var number_r_cur = Double(self.ValueTo.text!)
            if number_l_cur != nil && currency_val_cur != nil{
                DispatchQueue.main.async(execute: {
                self.ValueTo.text = String(format:"%.3f", currency_val_cur! * number_l_cur!)
                })
            }
    }

    // ++ функционал фоновой загрузки данных о доступных валютах ++ отлов работы вне интернета
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
                            DispatchQueue.main.async {
                                self.DateLabel.text = date
                                self.DataReadyLabel.alpha = 0
                                self.DataReadyLabel.text = "Данные обновлены!"
                                self.DataReadyLabel.isHidden = false
                                self.ChangeRatesOutlet.isHidden = false
                                UIView.animate(withDuration: 2.5) {
                                    self.DataReadyLabel.alpha = 1
                                }
                                UIView.animate(withDuration: 2.5, animations: {
                                    self.DataReadyLabel.alpha = 0
                                }) { (finished) in
                                    self.DataReadyLabel.isHidden = finished
                                }
                                UIView.animate(withDuration: 1, animations: {
                                    self.NoInternetConnectionImage.alpha = 0
                                }) { (finished) in
                                    self.NoInternetConnectionImage.isHidden = finished
                                }
                                
                            }
                        }
                        self.flag = true
                    }
                    catch
                    {
                        
                    }
                }
            }
            else
            {
                print("Не могу обновить курсы!")
                self.flag = false
                self.ChangeRatesOutlet.isHidden = true
                self.NoInternetConnectionImage.alpha = 1
                self.present(self.internetFailAlert, animated: true, completion: nil)

            }
            DispatchQueue.main.async {
                self.LoadInd.stopAnimating()
                self.CurrencyList_after.reloadAllComponents()
                self.CurrencyList_from.reloadAllComponents()
                self.CurrencyList_from.selectRow(30, inComponent: 0, animated: true)
                self.CurrencyList_after.selectRow(25, inComponent: 0, animated: true)
                // USD to RUB popular request
                self.WelcomeLabel.alpha = 0
                self.WelcomeLabel.text = "Выберите Валюту"
                self.WelcomeLabel.isHidden = false
                UIView.animate(withDuration: 1) {
                    self.WelcomeLabel.alpha = 1
                }
                self.updateCurrentCurrency()
                
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
    
    // парсинг данных о конкретной валюте
    func parseCur(data: Data?, toCurrency: String) -> String{
        var str = ""
        
        do{
            let json = try? JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String,Any>
            if let parsed_json = json{
                if let cur_rates = parsed_json?["rates"] as? Dictionary<String, Double>{
                    if let elem = cur_rates[toCurrency] {
                        str = String(format:"%.3f", elem)
                    }
                    else
                    {
                        str = ""
                    }
                }
                else
                {
                   print("Can't find _rates_ in json")
                }
            }
            else
            {
                print("JSON can't be parsed. No data available!")
                self.present(self.dataErrorAlert, animated: true, completion: nil)
            }
        }
        return str
    }
    
    func retrieveCurrency(baseCurrency: String, toCurrency: String, completion: @escaping(String) -> Void) {
        self.requestCurrency(baseCurrency: baseCurrency) { [weak self] (data, error) in
        var string = ""
        
            if let currentError = error{
                print(currentError.localizedDescription)
                self?.present((self?.internetFailAlert)!, animated: true, completion: nil)
            }
            else{
                string = (self?.parseCur(data: data, toCurrency: toCurrency))!
            }
        completion(string)
       }
    }
    
    // обновление валютного центрального лейбла 
    func updateCurrentCurrency() {
        if flag{
            self.CurrencyLabel.text = ""
            self.LoadInd.startAnimating()
            let baseCurrencyIndex = self.CurrencyList_from.selectedRow(inComponent: 0)
            let toCurrencyIndex = self.CurrencyList_after.selectedRow(inComponent: 0)
            let baseCurrency = self.currencies[baseCurrencyIndex]
            let toCurrency = self.currencies[toCurrencyIndex]
        
            self.retrieveCurrency(baseCurrency: baseCurrency, toCurrency: toCurrency) { [weak self] (val) in
                DispatchQueue.main.async(execute: {
                    self?.CurrencyLabel.text = val
                    self?.updateRightTextField()
                    self?.LoadInd.stopAnimating()
                    
                })
            }
        }

    }


}

