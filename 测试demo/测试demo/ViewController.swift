import UIKit

class CustomFlowLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        
        guard let collectionView = collectionView else { return }
        
        // 设置单元格的宽度为 collectionView 宽度的 70%，高度为 collectionView 高度的 80%
        // 这样可以确保单元格比视图宽度小，留出足够空间显示两边的部分单元格
        let inset: CGFloat = collectionView.bounds.width * 0.15
        let itemWidth = collectionView.bounds.width - 2 * inset
        let itemHeight = collectionView.bounds.height * 0.8
        
        itemSize = CGSize(width: itemWidth, height: itemHeight)
        minimumLineSpacing = 20
        
        // 设置 sectionInset 为视图宽度的 15%，确保两边显示更多部分
        sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        
        // 设置 collectionView 的减速率为 fast，使滚动更加灵敏
        collectionView.decelerationRate = .fast
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // 获取当前可见范围内的布局属性
        let layoutAttributes = super.layoutAttributesForElements(in: rect)?.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
        
        guard let collectionView = collectionView else { return layoutAttributes }
        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
        
        // 遍历所有布局属性，计算每个单元格的缩放和透明度
        layoutAttributes?.forEach { attributes in
            let distance = abs(attributes.center.x - centerX)
            let scale = max(0.75, 1 - (distance / collectionView.bounds.width))
            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
            attributes.alpha = scale
        }
        
        return layoutAttributes
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // 在视图边界改变时使布局无效，从而触发重新布局
        return true
    }
    
    /// 自定义分页逻辑，确保每次滑动停止时，最近的单元格居中显示。
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {
            return proposedContentOffset
        }
        
        let collectionViewSize = collectionView.bounds.size
        let proposedContentOffsetCenterX = proposedContentOffset.x + collectionViewSize.width / 2
        
        // 获取当前可见范围内的布局属性
        let layoutAttributes = self.layoutAttributesForElements(in: collectionView.bounds)
        
        var candidateAttributes: UICollectionViewLayoutAttributes?
        for attributes in layoutAttributes! {
            if attributes.representedElementCategory != .cell {
                continue
            }
            
            // 找到距离 proposedContentOffset 最近的单元格
            if candidateAttributes == nil {
                candidateAttributes = attributes
                continue
            }
            
            if abs(attributes.center.x - proposedContentOffsetCenterX) < abs(candidateAttributes!.center.x - proposedContentOffsetCenterX) {
                candidateAttributes = attributes
            }
        }
        
        // 返回使最近单元格居中的 contentOffset
        return CGPoint(x: candidateAttributes!.center.x - collectionViewSize.width / 2, y: proposedContentOffset.y)
    }
}

class CardCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        // 自定义单元格的外观
        backgroundColor = .blue
        layer.cornerRadius = 10
    }
}

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化并设置自定义布局
        let layout = CustomFlowLayout()
        layout.scrollDirection = .horizontal
        
        // 创建并配置 UICollectionView
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CardCollectionViewCell.self, forCellWithReuseIdentifier: "CardCell")
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.clipsToBounds = false // 允许单元格超出边界
        collectionView.isPagingEnabled = false // 禁用默认分页
        
        // 将 UICollectionView 添加到视图
        view.addSubview(collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // 返回单元格的数量
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCell", for: indexPath) as! CardCollectionViewCell
        // 配置单元格
        return cell
    }
}
