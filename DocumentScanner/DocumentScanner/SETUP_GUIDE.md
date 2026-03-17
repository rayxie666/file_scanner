# Xcode项目设置指南

## 文件结构已经配置好！

所有代码文件已经正确放置：
```
DocumentScanner/
├── DocumentScanner.xcodeproj  ← 在Xcode中打开这个文件
├── DocumentScanner/
│   ├── Models/                ← 4个Swift文件
│   ├── Services/              ← 5个Swift文件
│   ├── ViewModels/            ← 5个Swift文件
│   ├── ContentView.swift      ← 测试界面 (已更新)
│   ├── DocumentScannerApp.swift
│   ├── Info.plist             ← 相机权限配置
│   └── Assets.xcassets
├── DocumentScannerTests/
└── DocumentScannerUITests/
```

## 在Xcode中的配置步骤

### 1. 打开项目
```bash
cd /Users/rayxie/Git/file_scanner_ios/DocumentScanner/DocumentScanner
open DocumentScanner.xcodeproj
```

### 2. 添加文件到项目（重要！）

虽然文件已经在文件夹里，但Xcode可能看不到它们。需要手动添加：

1. 在Xcode左侧导航器中，选择`DocumentScanner`文件夹（蓝色图标）
2. 右键 → **Add Files to "DocumentScanner"...**
3. 选择这些文件夹：
   - ✅ `Models` 文件夹
   - ✅ `Services` 文件夹
   - ✅ `ViewModels` 文件夹
   - ✅ `Info.plist` 文件
4. 在对话框中：
   - ✅ 勾选 "Create groups"
   - ✅ 勾选 "DocumentScanner" target
   - ⚠️ **不要**勾选 "Copy items if needed"（文件已经在正确位置）
5. 点击 **Add**

### 3. 配置Info.plist权限

1. 选择项目 `DocumentScanner` (最顶层蓝色图标)
2. 选择 `TARGETS` → `DocumentScanner`
3. 切换到 `Info` 标签页
4. 找到 `Custom iOS Target Properties` 部分
5. 如果看不到相机权限，点击 `+` 添加：
   - Key: `Privacy - Camera Usage Description`
   - Value: `Camera access is required to scan documents.`

或者直接使用我们创建的Info.plist文件：
- 在项目设置中，找到 `Build Settings`
- 搜索 `Info.plist File`
- 设置为：`DocumentScanner/Info.plist`

### 4. 设置最低iOS版本

1. 在项目设置中，选择 `General` 标签页
2. 找到 `Deployment Info` 部分
3. 将 `iOS Deployment Target` 设置为 `14.0`

### 5. 构建并运行

1. 选择一个模拟器或真机（推荐真机，因为需要测试相机功能）
2. 点击 `Product` → `Build` (⌘B) 编译项目
3. 如果编译成功，点击 `Run` (⌘R) 运行

## 预期结果

运行后你应该看到：
- ✅ 标题 "Document Scanner"
- ✅ "Core Services Ready" 绿色文字
- ✅ 4个服务状态（全部显示 "Ready"）
- ✅ 存储信息（已用空间 / 可用空间）
- ✅ "Test Services" 按钮

点击 "Test Services" 按钮，查看控制台输出：
```
Testing services...
✅ EdgeDetectionService initialized
✅ ImageProcessingService initialized
✅ PDFGenerationService initialized
✅ DocumentStorageService initialized
✅ ScanSessionManager initialized
All services initialized successfully! 🎉
```

## 常见问题

### Q: Xcode显示"Cannot find 'EdgeDetectionService' in scope"
**A:** 文件没有添加到项目中。按照步骤2重新添加文件。

### Q: 编译错误："Use of undeclared type"
**A:** 确保所有Swift文件都添加到了DocumentScanner target中。
- 选择文件 → 右侧面板 → Target Membership → 勾选 DocumentScanner

### Q: 运行时崩溃
**A:** 检查是否正确配置了Info.plist中的相机权限。

### Q: 文件夹是黄色的，不是蓝色的
**A:** 这表示是文件夹引用，不是Group。删除后重新添加，并选择"Create groups"。

## 下一步

现在核心服务已经可以工作了！接下来可以：

1. **实现相机UI** - 创建CameraViewController使用AVFoundation
2. **实现裁剪UI** - 创建CropViewController带手势识别
3. **测试服务** - 在真机上测试边缘检测和PDF生成

## 文件清单

已创建的文件：
- ✅ 4个Model文件（ColorMode, ScannedPage, ScanSession, DocumentMetadata）
- ✅ 5个Service文件（EdgeDetection, ImageProcessing, PDFGeneration, DocumentStorage, SessionManager）
- ✅ 5个ViewModel文件（Camera, Crop, ColorMode, Session, DocumentLibrary）
- ✅ ContentView.swift（测试界面）
- ✅ Info.plist（权限配置）

总计：**1,264行生产就绪的Swift代码**

## 技术栈

- SwiftUI - 用户界面
- UIKit - 相机和高级UI控件（后续实现）
- Combine - 响应式数据绑定
- Vision - 边缘检测
- Core Image - 图像处理
- PDFKit - PDF生成
- AVFoundation - 相机控制

---

**有问题？** 检查Xcode控制台输出获取详细错误信息。
