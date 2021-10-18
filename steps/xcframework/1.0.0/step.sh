#!/bin/bash
set -ex

NAME=${framework_name}

function archive {
  xcodebuild archive \
  -scheme $1 \
  -destination "$2" \
  -archivePath "$3" \
  -configuration Release \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  BITCODE_GENERATION_MODE=bitcode \
  clean
}

function bitcodeSymbols {
  PATHS=($(pwd)/archives/$NAME/$1/$NAME.xcarchive/BCSymbolMaps/*)
  SYMBOLS=""
  for path in "${PATHS[@]}"; do
    SYMBOLS="$SYMBOLS -debug-symbols $path "
  done
  echo $SYMBOLS
}

# macOS

archive $NAME "generic/platform=macOS" "archives/$NAME/macOS/$NAME"
archive $NAME "generic/platform=macOS,variant=Mac Catalyst" "archives/$NAME/macOS Catalyst/$NAME"

# iOS

archive $NAME "generic/platform=iOS" "archives/$NAME/iOS/$NAME"
archive $NAME "generic/platform=iOS Simulator" "archives/$NAME/iOS Simulator/$NAME"

# watchOS

archive $NAME "generic/platform=watchOS" "archives/$NAME/watchOS/$NAME"
archive $NAME "generic/platform=watchOS Simulator" "archives/$NAME/watchOS Simulator/$NAME"

# tvOS

archive $NAME "generic/platform=tvOS" "archives/$NAME/tvOS/$NAME"
archive $NAME "generic/platform=tvOS Simulator" "archives/$NAME/tvOS Simulator/$NAME"

# xcframework

xcodebuild -create-xcframework \
-framework "archives/$NAME/macOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/macOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/macOS Catalyst/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/macOS Catalyst/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/iOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/iOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
$(bitcodeSymbols "iOS") \
-framework "archives/$NAME/iOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/iOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/watchOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/watchOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
$(bitcodeSymbols "watchOS") \
-framework "archives/$NAME/watchOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/watchOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-framework "archives/$NAME/tvOS/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/tvOS/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
$(bitcodeSymbols "tvOS") \
-framework "archives/$NAME/tvOS Simulator/$NAME.xcarchive/Products/Library/Frameworks/$NAME.framework" \
-debug-symbols "$(pwd)/archives/$NAME/tvOS Simulator/$NAME.xcarchive/dSYMs/$NAME.framework.dSYM" \
-output "archives/$NAME.xcframework"

# fix xcframework
find "archives/$NAME.xcframework" -name "*.swiftinterface" -exec sed -i -e "s/${NAME}\.//g" {} \;

# zip

cd archives
zip -r ${output_dir}/$NAME.zip $NAME.xcframework
