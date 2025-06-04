#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
copied_count=0
decompiled_count=0
failed_count=0

echo "Starting Lua file processing..."
echo "Source: rootfs/"
echo "Destination: decompiled/"
echo

# Create decompiled directory if it doesn't exist
mkdir -p decompiled

# Find all .lua files in rootfs/
while IFS= read -r -d '' lua_file; do
    # Get relative path from rootfs/
    rel_path="${lua_file#rootfs/}"
    
    # Create destination path
    dest_file="decompiled/$rel_path"
    dest_dir=$(dirname "$dest_file")
    
    # Create destination directory if needed
    mkdir -p "$dest_dir"
    
    echo -n "Processing: $rel_path ... "
    
    # Check if file starts with shebang (indicating it's likely compiled bytecode)
    if head -c 14 "$lua_file" | grep -q "^#!/usr/bin/lua" 2>/dev/null; then
        # File has shebang, likely compiled bytecode - strip shebang and try to decompile
        temp_file=$(mktemp)
        # Skip the shebang line and extract the bytecode
        tail -n +2 "$lua_file" > "$temp_file"
        
        if java -jar ~/lib/unluac-miwifi.jar "$temp_file" > "$dest_file" 2>/dev/null; then
            echo -e "${YELLOW}decompiled${NC}"
            decompiled_count=$((decompiled_count + 1))
        else
            # Decompilation failed, copy original file
            cp "$lua_file" "$dest_file"
            echo -e "${RED}failed (copied as-is)${NC}"
            failed_count=$((failed_count + 1))
        fi
        
        rm -f "$temp_file"
    else
        # Check if file appears to be plaintext Lua
        if head -c 100 "$lua_file" | grep -q "^--\|^local\|^function\|^if\|^for\|^while\|^repeat\|^return\|^require" 2>/dev/null; then
            # File appears to be plaintext Lua, copy it directly
            cp "$lua_file" "$dest_file"
            echo -e "${GREEN}copied${NC}"
            copied_count=$((copied_count + 1))
        else
            # Try to decompile as-is
            if java -jar ~/lib/unluac-miwifi.jar "$lua_file" > "$dest_file" 2>/dev/null; then
                echo -e "${YELLOW}decompiled${NC}"
                decompiled_count=$((decompiled_count + 1))
            else
                # Decompilation failed, copy as-is
                cp "$lua_file" "$dest_file"
                echo -e "${RED}failed (copied as-is)${NC}"
                failed_count=$((failed_count + 1))
            fi
        fi
    fi
    
done < <(find rootfs/ -name "*.lua" -type f -print0)

echo
echo "Processing complete!"
echo -e "Files copied directly: ${GREEN}$copied_count${NC}"
echo -e "Files decompiled: ${YELLOW}$decompiled_count${NC}"
echo -e "Files failed (copied as-is): ${RED}$failed_count${NC}"
echo "Total files processed: $((copied_count + decompiled_count + failed_count))" 