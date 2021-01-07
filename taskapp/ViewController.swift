//
//  ViewController.swift
//  taskapp
//
//  Created by 豊田修平 on 2020/12/27.
//

import UIKit
import RealmSwift
import UserNotifications    // 追加

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            tableView.delegate = self
            tableView.dataSource = self
        }
    
        // Realmインスタンスを取得する
        let realm = try! Realm()  // ←追加

        // DB内のタスクが格納されるリスト。
        // 日付の近い順でソート：昇順
        // 以降内容をアップデートするとリスト内は自動的に更新される。
        var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
        //★Taskクラスで定義した空のリストを作るというイメージで合っている?上のrealmのインスタンスはなぜ作成する必要がある?
    
        // データの数（＝セルの数）を返すメソッド
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return taskArray.count
            //taskArrayの行数(要素数)を入れている。
        }

        // 各セルの内容を返す(表示する)メソッド
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            // 再利用可能な cell を得る
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            //withIdentifierに入っている"Cell"はTable View Cellを挿入したときにIdenfierとして設定したCell
            
            // cellのtextLabel?のtextに、taskArrayから取得したtitleを設定する.
            let task = taskArray[indexPath.row]
            cell.textLabel?.text = task.title

            //Dateformatterクラスは日付を表すDareクラスを任意の形の文字列に変換
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"

            //cellのdetailTextLabel?のtextに、taskArrayから取得したdateを設定する.
            let dateString:String = formatter.string(from: task.date)
            cell.detailTextLabel?.text = dateString
            
            return cell
        }

        // 各セルを選択した時に実行されるメソッド
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            performSegue(withIdentifier: "cellSegue", sender:nil)
            //セルを選択した時にID:cellSegueを指定してSegueさせる
        }

        // セルが削除が可能なことを伝えるメソッド
        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
            return .delete
        }

        // Delete ボタンが押された時に呼ばれるメソッド
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            
            if editingStyle == .delete {
                // 削除するタスクを取得する
                let task = self.taskArray[indexPath.row]

                // ローカル通知をキャンセルする
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

                // データベースから削除する
                try! realm.write {
                    self.realm.delete(task) //★この行はDBの行削除を意味している?
                    tableView.deleteRows(at: [indexPath], with: .fade) //★この行は何のために必要か?
                }

                // 未通知のローカル通知一覧をログ出力
                center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                    for request in requests {
                        print("/---------------")
                        print(request)
                        print("---------------/")
                    }
                }
            } // --- ここまで変更 ---
        }
    
    // segue で画面遷移する時に呼ばれる
     override func prepare(for segue: UIStoryboardSegue, sender: Any?){
         let inputViewController:InputViewController = segue.destination as! InputViewController

         if segue.identifier == "cellSegue" {
             let indexPath = self.tableView.indexPathForSelectedRow
             inputViewController.task = taskArray[indexPath!.row]
            //SegueのidentifierがcellSegueの場合、つまりセルをタップしたときにtaskArrayの内容を遷移先のtaskに入れる。
         } else {
             let task = Task()

             let allTasks = realm.objects(Task.self)
             if allTasks.count != 0 {
                 task.id = allTasks.max(ofProperty: "id")! + 1
             //Taskに入っている行の数が0の場合はidが初期値ゼロで良いが、0以外の場合はDBの一番下に入れるため最大の列番+1してidを設定
             }
            //idだけ決めてあげて、あとは空の状態のtaskを遷移先のtaskに入れている。
             inputViewController.task = task
         }
     }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    
    }

