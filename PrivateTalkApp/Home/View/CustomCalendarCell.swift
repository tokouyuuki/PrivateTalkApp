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
        static let STACK_VIEW_SPACING = 2.0
        static let STACK_VIEW_TOPANCHOR_CONSTRAINT = 15.0
        static let STACK_VIEW_LEADINGANCHOR_CONSTRAINT = 2.0
        static let STACK_VIEW_TRAILINGANCHOR_CONSTRAINT = -2.0
        static let TITLE_LABEL_TOPANCHOR_CONSTRAINT = 10.0
        static let TITLE_LABEL_LEADINGANCHOR_CONSTRAINT = 0.0
        static let TITLE_LABEL_TRAILINGANCHOR_CONSTRAINT = 0.0
        static let RADIUS = 20.0
        static let DIAMETER = 40.0
        static let SUB_TITLE_LABEL_FONT_SIZE = 10.0
        static let SUB_TITLE_LABEL_CORNER_RADIUS = 4.0
        static let DEGREE_OF_BRIGHTENING_IN_THE_LIGHT = 0.5
        static let DEGREE_OF_BRIGHTENING_IN_THE_DARK = 1.7
        static let SUB_TITLE_LABEL_BACKGROUND_COLOR_ALPHA = 0.3
        static let SUB_TITLE_LABEL_HEIGHTANCHOR_CONSTRAINT = 15.0
        static let MIN_NUMBER_OF_LABEL_CANNOT_BE_DISPLAY = 4
        static let INDEX_OF_LABEL_CANNOT_BE_DISPLAY = 2
        static let PLUS = "+"
        static let BADGE_FONT_SIZE = 10.0
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
        stackView.spacing = Constants.STACK_VIEW_SPACING
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
            self.titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                 constant: Constants.TITLE_LABEL_TOPANCHOR_CONSTRAINT),
            self.titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                     constant: Constants.TITLE_LABEL_LEADINGANCHOR_CONSTRAINT),
            self.titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                      constant: Constants.TITLE_LABEL_TRAILINGANCHOR_CONSTRAINT),
            self.stackView.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor,
                                                   constant: Constants.STACK_VIEW_TOPANCHOR_CONSTRAINT),
            self.stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                    constant: Constants.STACK_VIEW_LEADINGANCHOR_CONSTRAINT),
            self.stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                     constant: Constants.STACK_VIEW_TRAILINGANCHOR_CONSTRAINT)
        ])
    }
    
    /// 丸印のレイアウトを更新
    /// 継承元の日付タイトルが構築される前の状態で、丸印の位置が決まってしまう。
    /// 日付タイトルに合わせて丸印を配置しているため、更新する必要がある。
    private func updateCircleLayerLayout() {
        // ラベルの中心に円のレイヤーを配置
        let circleX = self.titleLabel.frame.midX - Constants.RADIUS
        let circleY = contentView.frame.minY
        let rect = CGRect(x: circleX, y: circleY, width: Constants.DIAMETER, height: Constants.DIAMETER)

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
        label.font = UIFont.systemFont(ofSize: Constants.SUB_TITLE_LABEL_FONT_SIZE, weight: .bold)
        label.layer.cornerRadius = Constants.SUB_TITLE_LABEL_CORNER_RADIUS
        label.clipsToBounds = true
        label.text = event.title
        label.textColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                return UIColor(cgColor: event.calendar.cgColor)
                    .adjustedBrightness(by: Constants.DEGREE_OF_BRIGHTENING_IN_THE_LIGHT)
            } else {
                return UIColor(cgColor: event.calendar.cgColor)
                    .adjustedBrightness(by: Constants.DEGREE_OF_BRIGHTENING_IN_THE_DARK)
            }
        })
        label.backgroundColor = UIColor(cgColor: event.calendar.cgColor)
            .withAlphaComponent(Constants.SUB_TITLE_LABEL_BACKGROUND_COLOR_ALPHA)
        
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: Constants.SUB_TITLE_LABEL_HEIGHTANCHOR_CONSTRAINT)
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
            if eventList.count < Constants.MIN_NUMBER_OF_LABEL_CANNOT_BE_DISPLAY {
                // イベントが３つ以下の場合、そのまま表示
                let label = self.createEventTitleLabel(eventList[i])
                self.stackView.addArrangedSubview(label)
            } else {
                // イベントが４つ以上の場合、イベント２つ ＋ "＋表示されてない残りの予定数"を表示
                if i < Constants.INDEX_OF_LABEL_CANNOT_BE_DISPLAY {
                    let label = self.createEventTitleLabel(eventList[i])
                    self.stackView.addArrangedSubview(label)
                } else {
                    let label = UILabel()
                    label.text = Constants.PLUS + "\(eventList.count - self.stackView.subviews.count)"
                    label.textAlignment = .center
                    label.font = UIFont.systemFont(ofSize: Constants.BADGE_FONT_SIZE, weight: .light)
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
