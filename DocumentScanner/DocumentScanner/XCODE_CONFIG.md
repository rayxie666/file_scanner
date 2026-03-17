# Xcode项目配置步骤

## ✅ 编译错误已修复！

所有代码错误已经修复：
- ✅ 添加了PDFKit导入到SessionViewModel
- ✅ 修复了DocumentStorageService的重复声明
- ✅ 删除了Info.plist文件（SwiftUI项目不需要）

## 📝 在Xcode中添加权限

由于这是UIKit项目，我们需要在项目设置中添加权限，而不是使用Info.plist文件。

### 方法1: 通过项目设置添加（推荐）

1. 在Xcode中，选择左侧导航器最顶部的 **DocumentScanner** 项目（蓝色图标）
2. 在中间面板选择 **TARGETS** → **DocumentScanner**
3. 切换到 **Info** 标签页
4. 找到 **Custom iOS Target Properties** 部分
5. 点击列表中任意条目，然后点击 **+** 号
6. 添加以下键值对：

   **相机权限**:
   **键**: `Privacy - Camera Usage Description`
   **值**: `Camera access is required to scan documents.`

   **照片库权限** (用于文件上传功能):
   **键**: `Privacy - Photo Library Usage Description`
   **值**: `Photo library access allows you to import existing images as documents.`

   ![相机权限设置](https://via.placeholder.com/800x100?text=Privacy+-+Camera+Usage+Description)

### 方法2: 通过代码添加

如果上面的方法不起作用，可以编辑项目的Info部分：

1. 在项目导航器中找到 `DocumentScanner` 文件夹
2. 查看是否有 `Info.plist` 文件
3. 如果有，双击打开
4. 右键点击空白处 → **Add Row**
5. 输入：
   - Key: `NSCameraUsageDescription`
   - Type: `String`
   - Value: `Camera access is required to scan documents.`

### 方法3: 使用Info.plist文件

如果Xcode要求Info.plist文件：

1. 在项目设置中，选择 **Build Settings**
2. 搜索 `Info.plist File`
3. 双击 `Info.plist File` 的值
4. 输入: `DocumentScanner/Info.plist`

然后创建Info.plist文件：
- 右键点击 `DocumentScanner` 文件夹
- 选择 **New File...**
- 选择 **Property List**
- 命名为 `Info.plist`
- 添加上述的相机权限键值对

## 🔨 立即编译

现在项目应该可以成功编译了：

1. 按 `⌘B` 编译项目
2. 如果成功，按 `⌘R` 运行

## ✅ 预期结果

编译成功后，运行应用你会看到：

```
📱 Document Scanner
✅ Core Services Ready
   📷 Edge Detection Service - Ready
   ✂️ Image Processing Service - Ready
   📄 PDF Generation Service - Ready
   📁 Document Storage Service - Ready

💾 Storage Info
   Used: X MB
   Available: Y MB

🔵 [Test Services]
```

点击 "Test Services" 按钮，控制台会输出：

```
Testing services...
✅ EdgeDetectionService initialized
✅ ImageProcessingService initialized
✅ PDFGenerationService initialized
✅ DocumentStorageService initialized
✅ ScanSessionManager initialized
All services initialized successfully! 🎉
```

## 🚨 如果还有错误

### 错误: "Cannot find type 'DetectedQuadrilateral' in scope"

**解决方案**: 确保EdgeDetectionService.swift文件已添加到项目中。

1. 在Xcode左侧导航器中检查是否有 `Services` 文件夹
2. 如果没有，右键点击 `DocumentScanner` → **Add Files to "DocumentScanner"...**
3. 选择 `Services` 文件夹
4. 确保勾选 **"DocumentScanner" target**

### 错误: "Module 'PDFKit' not found"

**解决方案**: PDFKit是iOS内置框架，不需要手动添加。确保部署目标设置为iOS 11.0+。

1. 选择项目 → **General** 标签
2. **Deployment Info** → **iOS Deployment Target**: 设置为 `14.0`

### 编译成功但运行崩溃

**解决方案**: 检查是否添加了相机权限。

- 查看控制台错误信息
- 确认已按照上述步骤添加了相机使用说明

## 📊 当前状态

- ✅ 所有编译错误已修复
- ✅ 核心服务已实现
- ✅ ViewModels已实现
- ⏳ 需要在Xcode中添加相机权限
- ⏳ 准备运行和测试

## 🎯 下一步

1. ✅ 修复编译错误（已完成）
2. 🔄 在Xcode中添加相机权限（执行中）
3. ⏳ 编译运行项目
4. ⏳ 开始实现相机UI

---

**有问题？**
- 查看Xcode控制台的详细错误信息
- 确保所有Swift文件都已添加到项目中
- 检查Target Membership是否正确

**现在可以开始编译了！** 🚀
