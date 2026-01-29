#!/bin/bash
# SAFEGUARD: This script fixes "Quarantine" issues on macOS.
# It strips the "downloaded from internet" flag from all files in this folder.
# This fixes "Code Signature Invalid" and "Developer cannot be verified" errors.

echo "============================================"
echo "      SPM macOS Permission Fixer            "
echo "============================================"
echo ""
echo "This script will run: sudo xattr -cr ."
echo "You may be asked for your password."
echo ""

sudo xattr -cr .

if [ $? -eq 0 ]; then
    echo ""
    echo "SUCCESS: Permissions fixed. You can now run SPM."
else
    echo ""
    echo "ERROR: Something went wrong. Please check the error message above."
fi

# Keep window open
read -p "Press Enter to close..."
