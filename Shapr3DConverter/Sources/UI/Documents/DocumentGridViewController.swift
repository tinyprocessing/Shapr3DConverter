import Combine
import UIKit

protocol DocumentGridViewControllerDelegate: AnyObject {
    func didTapAddItem()
    func didTapDeleteItem(_ document: DocumentItem)
    func didOpenFile(_ url: URL)
}

final class DocumentGridViewController: BaseViewController {
    weak var documentDelegate: DocumentGridViewControllerDelegate?

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, DocumentItem>!
    private var cancellables = Set<AnyCancellable>()
    private let converterManager: DocumentConversionManaging

    private lazy var emptyStateView = EmptyStateView(
        title: .localized(.empty_view_title),
        description: .localized(.empty_view_subtitle)
    )

    init(converterManager: DocumentConversionManaging) {
        self.converterManager = converterManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        setupEmptyStateView()
        setupDragAndDrop()
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
        collectionView.register(DocumentGridCell.self, forCellWithReuseIdentifier: DocumentGridCell.reuseIdentifier)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: Config.buttonOffset),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupEmptyStateView() {
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
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
                withReuseIdentifier: DocumentGridCell.reuseIdentifier,
                for: indexPath
            ) as? DocumentGridCell
            cell?.configure(with: item)
            return cell
        }
    }

    func updateItems(_ items: [DocumentItem]) {
        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<Section, DocumentItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)

        updateEmptyStateVisibility(isEmpty: items.isEmpty)
    }

    private func updateEmptyStateVisibility(isEmpty: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            emptyStateView.isHidden = !isEmpty
            collectionView.isHidden = isEmpty
        }
    }

    private func setupDragAndDrop() {
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
    }
}

extension DocumentGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        let actionSheet = DocumentDetailViewController(document: item,
                                                       conversionManager: converterManager)
        if traitCollection.userInterfaceIdiom == .pad {
            actionSheet.modalPresentationStyle = .popover
            if let cell = collectionView.cellForItem(at: indexPath) {
                actionSheet.popoverPresentationController?.sourceView = cell
                actionSheet.popoverPresentationController?.sourceRect = cell.bounds
                actionSheet.popoverPresentationController?.permittedArrowDirections = [.any]
            }
        } else {
            actionSheet.modalPresentationStyle = .pageSheet
        }
        present(actionSheet, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return nil }

        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil) { [weak self] _ in
            let deleteAction = UIAction(title: .localized(.delete),
                                        image: Config.trashImage,
                                        attributes: .destructive) { _ in
                self?.documentDelegate?.didTapDeleteItem(item)
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
}

extension DocumentGridViewController: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        let providers = session.items.compactMap { $0.itemProvider }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(Config.shaprUTI) {
            provider.loadItem(forTypeIdentifier: Config.shaprUTI, options: nil) { [weak self] urlData, _ in
                guard let self, let fileURL = urlData as? URL else { return }

                DispatchQueue.main.async {
                    if fileURL.pathExtension.lowercased() == Constants.fileExtension {
                        self.documentDelegate?.didOpenFile(fileURL)
                    }
                }
            }
        }
    }
}

extension DocumentGridViewController {
    fileprivate enum Config {
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
        static let trashImage: UIImage? = UIImage(systemName: "trash")

        static func columns(for width: CGFloat) -> Int {
            switch width {
            case ..<400: return 2
            case 400..<700: return 3
            case 700..<1000: return 4
            default: return 5
            }
        }

        static let shaprUTI = "tinyprocessing.com.shapr3dconverter.shapr"
    }
}

extension DocumentGridViewController {
    fileprivate enum Section {
        case main
    }
}
