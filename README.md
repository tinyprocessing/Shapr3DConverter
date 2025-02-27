# Shapr3DConverter - Project Documentation

🚩 Warning About This Company's Hiring Process 🚩 I completed a 4+ day take-home technical task for this company, only to be ignored for two weeks after submission, despite following up. Eventually, they rejected my application without meaningful feedback, showing a complete lack of respect for candidates' time and effort. If a company assigns an extensive unpaid task, the least they can do is provide timely updates and proper feedback. This experience raises serious red flags about their hiring process and professionalism. Engineers, be warned—your time is valuable, and you deserve better. 🚨

## Overview
Shapr3DConverter is an iOS application designed for converting and managing documents in various formats. The project follows a structured architecture to maintain modularity, reusability, and scalability.

## Project Structure

### 1. **App Entry Points**
- `main.swift` - Entry point of the application.
- `AppDelegate.swift` - Manages app lifecycle events.
- `SceneDelegate.swift` - Handles scene-based lifecycle events.

### 2. **Resources**
- `Assets.xcassets` - Stores app images, icons, and color assets.
- `Localizable.strings` - Contains localized strings for **English (en)**, **Spanish (es)**, and **Hungarian (hu)**.
- `Icons/` - Contains app-specific icons.

### 3. **Common UI Components**
- `BaseViewController.swift` - A reusable base class for all view controllers.
- `CircularProgressView.swift` - A reusable UI component for showing progress.

### 4. **Constants & Localization**
- `Colors.swift` - Defines application-wide color constants.
- `Constants.swift` - Holds reusable constant values.
- `Localized.swift` - Handles localized string management.

### 5. **Coordinator Pattern Implementation**
- `ApplicationCoordinator.swift` - Manages the root navigation of the app.
- `DocumentsCoordinator.swift` - Handles document-related screen flow.

### 6. **Document Management Services**
- `DocumentCacheManager.swift` - Handles caching of document data.
- `DocumentConversionEngine.swift` - Performs actual document format conversions.
- `DocumentConversionManager.swift` - Manages document conversion requests and processing.

### 7. **Extensions**
- `UIColor+Extensions.swift` - Provides additional utilities for color handling.
- `UIImage+Extensions.swift` - Extends image functionality.

### 8. **Routing System**
- `Route.swift` - Defines navigation paths and routes.
- `Router.swift` - Manages in-app navigation.

### 9. **UI Modules**
#### **Document Detail View**
- `DocumentDetailViewController.swift` - Displays detailed information about a document.
- `DocumentDetailView.swift` - Handles document detail UI layout.

#### **Document Grid View**
- `DocumentGridViewController.swift` - Displays a grid of available documents.
- `DocumentEmptyStateView.swift` - UI for empty document state.
- `DocumentGridCell.swift` - Represents a single document cell in the grid.

#### **Document Models**
- `DocumentItem.swift` - Defines a document model.
- `DocumentItemCached.swift` - Defines a cached document model.

### 10. **Utilities**
- `CombineAsyncStreamBridge.swift` - Bridges Combine with async/await.
- `Publisher+SingleOutput.swift` - Helps in managing Combine publishers.
- `CombineUtils.swift` - Utility functions for working with Combine framework.

## Summary
This documentation provides an overview of the core components of the **Shapr3DConverter** project. The app follows the **MVVM + Coordinator** pattern, integrates Combine for reactive programming, and ensures modular design with reusable UI components and services.

