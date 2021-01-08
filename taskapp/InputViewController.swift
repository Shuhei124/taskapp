//
//  InputViewController.swift
//  taskapp
//
//  Created by 豊田修平 on 2020/12/29.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController {


    @IBOutlet weak var tittleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var categoryTextField: UITextField!
    
    let realm = try! Realm()
    var task: Task!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する(入力を閉じる処理)
        //chap6.10 ユーザーの利便性を高めるために画面の背景をタップしたらキーボードを閉じる
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)

        //ViewControllerから受け取った値の設定。プラスボタンの場合はTaskで定義したように空白になる。
        //chap6.10・タスク一覧画面から遷移してきたときに受け取ったタスクの情報をUIに反映させる。
        tittleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        categoryTextField.text = task.category
        
        let borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        contentsTextView.layer.borderColor = borderColor
        contentsTextView.layer.borderWidth = 0.5
        contentsTextView.layer.cornerRadius = 5.0
        contentsTextView.layer.masksToBounds = true

        
    }
    
    //元の画面に戻るときにreamを使ってtaskの内容をDBに書き込む
    //chap6.10 ・タスク一覧画面に戻るときにUIに入力された値をデータベースに保存する。
    override func viewWillDisappear(_ animated: Bool) {
        try! realm.write {
            self.task.title = self.tittleTextField.text!
            self.task.contents = self.contentsTextView.text!
            self.task.date = self.datePicker.date
            self.task.category = self.categoryTextField.text!
            self.realm.add(self.task, update: .modified)
        }
        
        setNotification(task: task)
        
        super.viewWillDisappear(animated)
        //★これは何のために必要?
    }
    
    
    // タスクのローカル通知を登録する --- ここから ---
     func setNotification(task: Task) {
        //UMMutableNotificationContentのインスタンスを作成
         let content = UNMutableNotificationContent()
         // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
         if task.title == "" {
             content.title = "(タイトルなし)"
         } else {
             content.title = task.title
         }
         if task.contents == "" {
             content.body = "(内容なし)"
         } else {
             content.body = task.contents
         }
         content.sound = UNNotificationSound.default

         // ローカル通知が発動するtrigger（日付マッチ）を作成
         let calendar = Calendar.current
         let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
         let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

         // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
         let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)

         // ローカル通知を登録
         let center = UNUserNotificationCenter.current()
         center.add(request) { (error) in
             print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
         }

         // 未通知のローカル通知一覧をログ出力
         center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
             for request in requests {
                 print("/---------------")
                 print(request)
                 print("---------------/")
             }
         }
     } // --- ここまで追加 ---
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }

}
