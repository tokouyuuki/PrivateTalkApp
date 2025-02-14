//
//  CustomCalendarCell.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/24.
//

import Foundation
import FSCalendar
import EventKit

// MARK: - カレンダーのカスタムセル
final class CustomCalendarCell: FSCalendarCell {
    
    private struct Constants {
        static let PLUS = "+"
    }
    // セルのID
    static let identifier = "CustomCalendarCell"
    // 今日の日付の丸印のレイヤー
    private var todayCircleLayer: CAShapeLayer?
    // 選択時の日付の丸印のレイヤー
    private var selectedCircleLayer: CAShapeLayer?
    // StackView
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2.0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder!) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCircleLayerLayout()
    }
    
    /// セルが再利用される際に呼ばれる
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // 今日の日付と選択時の丸印をレイヤーから削除する
        if let layers = contentView.layer.sublayers {
            layers.forEach {
                if $0 is CAShapeLayer {
                    $0.removeFromSuperlayer()
                }
            }
        }
    }
    
    // MARK: - Privateメソッド
    /// セットアップ
    private func setup() {
        // 日付のオートレイアウトの制約を変更
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(self.stackView)
        
        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0),
            self.titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0.0),
            self.titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0.0),
            self.stackView.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 15.0),
            self.stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2.0),
            self.stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2.0)
        ])
    }
    
    /// 丸印のレイアウトを更新
    /// 継承元の日付タイトルが構築される前の状態で、丸印の位置が決まってしまう。
    /// 日付タイトルに合わせて丸印を配置しているため、更新する必要がある。
    private func updateCircleLayerLayout() {
        // ラベルの中心に円のレイヤーを配置
        let circleX = self.titleLabel.frame.midX - 20.0
        let circleY = contentView.frame.minY
        let rect = CGRect(x: circleX, y: circleY, width: 40.0, height: 40.0)

        // 今日の日付の印を丸印に設定
        if let todayCircleLayer = self.todayCircleLayer {
            self.todayCircleLayer?.frame = rect
            self.todayCircleLayer?.path = UIBezierPath(ovalIn: todayCircleLayer.bounds).cgPath
        }
        // 選択時の日付の印を丸印に設定
        if let selectedCircleLayer = self.selectedCircleLayer {
            self.selectedCircleLayer?.frame = rect
            self.selectedCircleLayer?.path = UIBezierPath(ovalIn: selectedCircleLayer.bounds).cgPath
        }
    }
    
    /// イベントタイトルのラベル生成
    /// - parameter event: イベント
    private func createEventTitleLabel(_ event: EKEvent) -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10.0, weight: .bold)
        label.layer.cornerRadius = 4.0
        label.clipsToBounds = true
        label.text = event.title
        label.textColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor(cgColor: event.calendar.cgColor).adjustedBrightness(by: 0.5)
            } else {
                return UIColor(cgColor: event.calendar.cgColor).adjustedBrightness(by: 1.7)
            }
        })
        label.backgroundColor = UIColor(cgColor: event.calendar.cgColor).withAlphaComponent(0.3)
        
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 15.0)
        ])
        
        return label
    }
    
    // MARK: - Publicメソッド
    /// イベントタイトルをセット
    /// - parameter eventList: イベントのリスト
    func setEventTitleLabels(_ eventList: [EKEvent]) {
        //　以前のStackView内のラベルを削除
        self.stackView.subviews.forEach {
            $0.removeFromSuperview()
        }
        for i in 0..<eventList.count {
            if eventList.count < 4 {
                // イベントが３つ以下の場合、そのまま表示
                let label = self.createEventTitleLabel(eventList[i])
                self.stackView.addArrangedSubview(label)
            } else {
                // イベントが４つ以上の場合、イベント２つ ＋ "＋表示されてない残りの予定数"を表示
                if i < 2 {
                    let label = self.createEventTitleLabel(eventList[i])
                    self.stackView.addArrangedSubview(label)
                } else {
                    let label = UILabel()
                    label.text = Constants.PLUS + "\(eventList.count - self.stackView.subviews.count)"
                    label.textAlignment = .center
                    label.font = UIFont.systemFont(ofSize: 10.0, weight: .light)
                    self.stackView.addArrangedSubview(label)
                    break
                }
            }
        }
    }
    
    /// 今日の日付の丸印をセット
    func setTodayCircleLayer() {
        // 丸印を描画するためのレイヤーを生成
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.symbol.cgColor
        contentView.layer.insertSublayer(shapeLayer, below: self.titleLabel.layer)
        self.todayCircleLayer = shapeLayer
    }
    
    /// 選択時の日付の丸印をセット
    func setSelectedCircleLayer() {
        // 選択したものが今日の日付だった場合、今日の日付の丸印を非表示にする
        if let todayCircleLayer = self.todayCircleLayer,
           !todayCircleLayer.isHidden {
            self.todayCircleLayer?.isHidden = true
        }
        // 丸印を描画するためのレイヤーを生成
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.symbol.cgColor
        contentView.layer.insertSublayer(shapeLayer, below: self.titleLabel.layer)
        self.selectedCircleLayer = shapeLayer
    }
    
    /// 丸印の設定をリセット
    func resetCircleLayer() {
        self.todayCircleLayer?.isHidden = false
        self.selectedCircleLayer?.isHidden = true
    }
}
