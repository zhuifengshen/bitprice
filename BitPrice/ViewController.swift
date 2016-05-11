//
//  ViewController.swift
//  BitPrice
//
//  Created by 张楚昭 on 16/5/11.
//  Copyright © 2016年 tianxing. All rights reserved.
//

import UIKit
import SwiftyJSON

class ViewController: UIViewController {
    
    var lastPrice:Double = 0.0

    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var differLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //显示并定时刷新比特币最新价格
        reloadPrice()
        //显示历史价格列表
        buildHistoryLabels(getLastFiveDayPrice())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //获取当前比特币最新价格
    func getLatestPrice() -> String?{
        let url = "http://api.coindesk.com/v1/bpi/currentprice/CNY.json"
        if let jsonData = NSData(contentsOfURL: NSURL(string: url)!){
            //使用 SwiftyJSON 来读取和解析返回的 JSON 数据
            let json = JSON(data: jsonData)
            return json["bpi"]["CNY"]["rate"].stringValue
        }else{
            return nil
        }
    }
    //每隔5秒刷新最新价格界面
    func reloadPrice(){
        //getLatestPrice()获取网络数据是同步操作,所以 GCD 线程异步调度
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {() -> Void in
            let price = self.getLatestPrice()
            //由于 UI 操作不能在异步线程中进行,所以我们这里切换回主线程调度
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                //每隔5秒刷新数据
                NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("reloadPrice"), userInfo: nil, repeats: false)
                if let tmp = price{
                    var nsPrice = tmp as NSString
                    //从服务端获取的数据格式为1,273.203,这里我们替换一下','符号
                    nsPrice = nsPrice.stringByReplacingOccurrencesOfString(",", withString: "")
                    let doublePrice = nsPrice.doubleValue
                    //计算涨跌幅度
                    let differPrice = doublePrice - self.lastPrice
                    //保存当前值,以便下次计算
                    self.lastPrice = doublePrice
                    self.priceLabel.text = NSString(format: "$ %.2f", doublePrice) as? String
                    //涨跌时字体分别显示不同颜色
                    if differPrice > 0{
                        self.differLabel.textColor = UIColor.redColor()
                        self.priceLabel.textColor = UIColor.redColor()
                        self.differLabel.text = NSString(format: "+%.2f", differPrice) as? String
                    }else{
                        self.differLabel.textColor = UIColor.greenColor()
                        self.priceLabel.textColor = UIColor.greenColor()
                        self.differLabel.text = NSString(format: "-%.2f", differPrice) as? String
                    }
                }
            })
        })
    }
    //显示最近5天比特币的报价
    func getLastFiveDayPrice() -> Array<(String,String)>{
        let curDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        //获取过去第六天日期对象
        let startDate = calendar.dateByAddingUnit(NSCalendarUnit.NSDayCalendarUnit, value: -6, toDate: curDate, options: NSCalendarOptions.WrapComponents)
        //获取过去第一天日期对象
        let endDate = calendar.dateByAddingUnit(NSCalendarUnit.NSDayCalendarUnit, value: -1, toDate: curDate, options: NSCalendarOptions.WrapComponents)
        //构建日期格式输出对象
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        //历史数据存储数组
        var result = Array<(String,String)>()
        //        print(formatter.stringFromDate(startDate!) + " " + formatter.stringFromDate(endDate!))
        //构建历史数据接口 URL
        let url = "http://api.coindesk.com/v1/bpi/historical/close.json?start=\(formatter.stringFromDate(startDate!))&end=\(formatter.stringFromDate(endDate!))&currency=CNY"
        //        print(url)
        //SwiftyJSON 获取并解析 json数据
        if let jsonData = NSData(contentsOfURL: NSURL(string: url)!){
            let json = JSON(data: jsonData)
            let bpiDict:JSON = json["bpi"]
            for (key,val) in bpiDict{
                result.append((key, val.stringValue))
            }
        }
        return result
    }
    //构建历史价格页面
    func buildHistoryLabels(priceList: Array<(String,String)>){
        //标记历史数据项间间距
        var count = 0.0
        //历史数据标题
        let labelTitle = UILabel(frame: CGRectMake(CGFloat(100.0),CGFloat(350.0),CGFloat(200.0),CGFloat(30)))
        labelTitle.text = "历史价格"
        labelTitle.textColor = UIColor.blueColor()
        labelTitle.textAlignment = NSTextAlignment.Center
        self.view.addSubview(labelTitle)
        //添加各个历史数据项
        for (date,price) in priceList{
            let labelHistory = UILabel(frame: CGRectMake(CGFloat(100.0),CGFloat(390 + count * 40.0), CGFloat(200.0), CGFloat(30.0)))
            labelHistory.text = "\(date) \(price)"
            labelHistory.textColor = UIColor.blueColor()
            labelHistory.textAlignment = NSTextAlignment.Center
            self.view.addSubview(labelHistory)
            count++
        }
    }

}

