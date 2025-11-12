#!/bin/bash
set -e

echo "🔍 Repository Cleanup Validation"
echo "================================"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Verify removed files don't exist
echo ""
echo "📝 Checking removed files..."
REMOVED_FILES=(
    "test-sqlite.js"
    "test-sqlite3.js"
    "tests/test-better-sqlite.js"
    "tests/test-claude-flow-memory.js"
)

for file in "${REMOVED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${YELLOW}⚠️  Still exists: $file${NC}"
    else
        echo -e "${GREEN}✅ Removed: $file${NC}"
    fi
done

# Check 2: Verify vectortest is removed or gitignored
echo ""
echo "📝 Checking vectortest directory..."
if [ -d "vectortest" ]; then
    if git ls-files --error-unmatch vectortest/ 2>/dev/null; then
        echo -e "${RED}❌ vectortest/ is still tracked by git${NC}"
    else
        echo -e "${GREEN}✅ vectortest/ exists but is gitignored${NC}"
    fi
else
    echo -e "${GREEN}✅ vectortest/ removed${NC}"
fi

# Check 3: Verify test databases are gitignored
echo ""
echo "📝 Checking test database tracking..."
TEST_DBS=(
    ".test_bm25_db"
    "test_accuracy_db"
    ".tantivy_index"
    ".serena"
    ".embed"
)

for db in "${TEST_DBS[@]}"; do
    if [ -d "$db" ]; then
        if git ls-files --error-unmatch "$db/" 2>/dev/null; then
            echo -e "${RED}❌ $db/ is tracked (should be gitignored)${NC}"
        else
            echo -e "${GREEN}✅ $db/ is gitignored${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  $db/ doesn't exist${NC}"
    fi
done

# Check 4: Verify Rust builds
echo ""
echo "📝 Testing Rust build..."
if cargo build --all-features 2>&1 | grep -q "error"; then
    echo -e "${RED}❌ Cargo build failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Cargo build succeeded${NC}"
fi

# Check 5: Verify tests pass
echo ""
echo "📝 Running Rust tests..."
if cargo test --all-features 2>&1 | tail -1 | grep -q "test result: ok"; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi

# Check 6: Verify binary utilities compile
echo ""
echo "📝 Checking binary utilities..."
BINARIES=(
    "tantivy_migrator:tantivy"
    "verify_symbols:tree-sitter"
    "test_persistence:tantivy"
)

for bin_spec in "${BINARIES[@]}"; do
    IFS=':' read -r bin feature <<< "$bin_spec"
    if cargo build --bin "$bin" --features "$feature" 2>&1 | grep -q "error"; then
        echo -e "${RED}❌ Failed to build binary: $bin${NC}"
    else
        echo -e "${GREEN}✅ Binary builds: $bin${NC}"
    fi
done

echo ""
echo "================================"
echo -e "${GREEN}✅ Validation complete!${NC}"
