"""
Update version number in BlueBreeze podspec.

This script updates the version number in the podspec file, including both
the spec.version and the git tag in spec.source.

Usage:
    python update_version.py <version>
    
Example:
    python update_version.py 0.1.2
"""

import sys
import re
from pathlib import Path


def update_podspec_version(version: str) -> bool:
    """
    Update version number in podspec file.
    
    Args:
        version: Version string (e.g., "0.1.2")
        
    Returns:
        True if successful, False otherwise
    """
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    podspec_path = project_root / "BlueBreeze.podspec"
    
    if not podspec_path.exists():
        print(f"✗ Podspec file not found: {podspec_path}")
        return False
    
    print(f"\n{'='*60}")
    print(f"Updating podspec to version {version}...")
    print('='*60)
    
    try:
        with open(podspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Update spec.version
        content = re.sub(
            r"spec\.version\s*=\s*['\"][\d.]+['\"]",
            f"spec.version       = '{version}'",
            content
        )
        
        # Update spec.source tag
        content = re.sub(
            r"(:tag\s*=>\s*['\"])[\d.]+(['\"])",
            f"\\g<1>{version}\\g<2>",
            content
        )
        
        with open(podspec_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✓ Updated podspec to version {version}")
        return True
        
    except Exception as e:
        print(f"✗ Failed to update podspec: {e}")
        return False


def main():
    """Main function to update version."""
    if len(sys.argv) != 2:
        print("Usage: python update_version.py <version>")
        print("Example: python update_version.py 0.1.2")
        sys.exit(1)
    
    version = sys.argv[1]
    
    # Validate version format (simple check)
    if not re.match(r'^\d+\.\d+\.\d+$', version):
        print(f"✗ Invalid version format: {version}")
        print("Version should be in format: X.Y.Z (e.g., 0.1.2)")
        sys.exit(1)
    
    if not update_podspec_version(version):
        sys.exit(1)
    
    print('='*60)


if __name__ == "__main__":
    main()
