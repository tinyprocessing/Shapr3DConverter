import Combine
import UIKit

protocol DocumentGridViewControllerDelegate: AnyObject {
    func didTapAddItem()
    func didSelect(document: DocumentItem)
}

final class DocumentGridViewController: BaseViewController {
    weak var documentDelegate: DocumentGridViewControllerDelegate?

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, DocumentItem>!
    private var cancellables = Set<AnyCancellable>()

    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(Config.plusImage, for: .normal)
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupAddButton()
        setupCollectionView()
        setupDataSource()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout = createLayout()
        collectionView.delegate = self
    }

    private func setupAddButton() {
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    @objc private func addButtonTapped() {
        documentDelegate?.didTapAddItem()
    }

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(DocumentCell.self, forCellWithReuseIdentifier: DocumentCell.reuseIdentifier)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: Config.buttonOffset),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { _, layoutEnvironment in
            let availableWidth = layoutEnvironment.container.effectiveContentSize.width
            let columns = Config.columns(for: availableWidth)

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
                heightDimension: .absolute(Config.itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(Config.itemHeight)
            )

            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                           repeatingSubitem: item,
                                                           count: columns)
            group.interItemSpacing = .fixed(Config.interItemSpacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = Config.interGroupSpacing
            section.contentInsets = Config.sectionInsets
            return section
        }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DocumentCell.reuseIdentifier,
                for: indexPath
            ) as? DocumentCell
            cell?.configure(with: item)
            return cell
        }
    }

    func updateItems(_ items: [DocumentItem]) {
        guard let dataSource = dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, DocumentItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

extension DocumentGridViewController {
    fileprivate struct Config {
        static let itemHeight: CGFloat = 150
        static let interItemSpacing: CGFloat = 10
        static let interGroupSpacing: CGFloat = 10
        static let sectionInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        static let buttonOffset: CGFloat = 10
        static let imageConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        static let plusImage = UIImage(
            systemName: "plus.circle.fill",
            withConfiguration: imageConfig
        )?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)

        static func columns(for width: CGFloat) -> Int {
            switch width {
            case ..<400: return 2
            case 400..<700: return 3
            case 700..<1000: return 4
            default: return 5
            }
        }
    }
}

extension DocumentGridViewController {
    fileprivate enum Section {
        case main
    }
}

extension DocumentGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = dataSource.itemIdentifier(for: indexPath) {
            documentDelegate?.didSelect(document: item)
        }
    }
}
