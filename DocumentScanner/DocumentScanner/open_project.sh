#!/bin/bash

echo "🚀 Opening DocumentScanner Xcode project..."
echo ""
echo "Project location:"
pwd
echo ""
echo "📁 File structure:"
ls -la DocumentScanner/ | grep -E "Models|Services|ViewModels|Info.plist"
echo ""
echo "✅ Opening in Xcode..."

open DocumentScanner.xcodeproj

echo ""
echo "📝 Next steps in Xcode:"
echo "1. Add files to project: Right-click DocumentScanner folder → Add Files"
echo "2. Select Models, Services, ViewModels folders + Info.plist"
echo "3. Build (⌘B) and Run (⌘R)"
echo ""
echo "📖 See SETUP_GUIDE.md for detailed instructions"
