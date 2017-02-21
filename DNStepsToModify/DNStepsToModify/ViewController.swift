//
//  ViewController.swift
//  DNStepsToModify
//
//  Created by mainone on 2017/2/21.
//  Copyright © 2017年 mainone. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    // 定义健康中心
    let healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    @IBOutlet weak var stepsNumberLabel: UILabel!
    @IBOutlet weak var addStepsTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshSteps()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshSteps()
    }
    
    func refreshSteps() {
        // 设置请求的权限,这里我们只获取读取和写入步数
        let stepType: HKQuantityType? = HKObjectType.quantityType(forIdentifier: .stepCount)
        let dataTypesToRead = NSSet(objects: stepType as Any)
        
        // 权限请求
        self.healthStore?.requestAuthorization(toShare: dataTypesToRead as? Set<HKSampleType>, read: dataTypesToRead as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            // 得到权限后就可以获取步数和写入了
            if success {
                self.fetchSumOfSamplesToday(for: stepType!, unit: HKUnit.count()) { (stepCount, error) in
                    // 获取到步数后,在主线程中更新数字
                    DispatchQueue.main.async {
                        self.stepsNumberLabel.text = "\(stepCount!)"
                    }
                }
            } else {
                let alert = UIAlertController(title: "提示", message: "不给权限我还怎么给你瞎写步数呢,可以去设置界面打开权限", defaultActionButtonTitle: "确定", tintColor: UIColor.red)
                alert.show()
            }
        })
    }
    
    // 添加数据
    @IBAction func addStepsBtnClick(_ sender: UIButton) {
        if let num = addStepsTextField.text {
            self.addstep(withStepNum: Double(num)!)
        }
    }
    
    func fetchSumOfSamplesToday(for quantityType: HKQuantityType, unit: HKUnit, completion completionHandler: @escaping (Double?, NSError?)->()) {
        let predicate: NSPredicate? = self.predicateForSamplesToday()
        
        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { query, result, error in
            
                var totalCalories = 0.0
                if let quantity = result?.sumQuantity() {
                    let unit = HKUnit.count()
                    totalCalories = quantity.doubleValue(for: unit)
                }
                completionHandler(totalCalories, error as NSError?)
        }

        self.healthStore?.execute(query)
    }
    
    func predicateForSamplesToday() -> NSPredicate {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date? = calendar.startOfDay(for: now)
        let endDate: Date? = calendar.date(byAdding: .day, value: 1, to: startDate!)
        return HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    }
    
    func addstep(withStepNum stepNum: Double) {
        let stepCorrelationItem: HKQuantitySample? = self.stepCorrelation(withStepNum: stepNum)
        self.healthStore?.save(stepCorrelationItem!, withCompletion: { (success, error) in
            DispatchQueue.main.async(execute: {() -> Void in
                if success {
                    self.view.endEditing(true)
                    self.addStepsTextField.text = ""
                    self.refreshSteps()
                    let alert = UIAlertController(title: "提示", message: "添加步数成功", defaultActionButtonTitle: "确定", tintColor: UIColor.red)
                    alert.show()
                } else {
                    let alert = UIAlertController(title: "提示", message: "添加步数失败", defaultActionButtonTitle: "确定", tintColor: UIColor.red)
                    alert.show()
                    return
                }
            })
        })
    }
    
    func stepCorrelation(withStepNum stepNum: Double) -> HKQuantitySample {
        let endDate = Date()
        let startDate = Date(timeInterval: -300, since: endDate)
        let stepQuantityConsumed = HKQuantity(unit: HKUnit.count(), doubleValue: stepNum)
        let stepConsumedType = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let stepConsumedSample = HKQuantitySample(type: stepConsumedType!, quantity: stepQuantityConsumed, start: startDate, end: endDate, metadata: nil)
        return stepConsumedSample
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }

}

