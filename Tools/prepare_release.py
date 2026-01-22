"""
Prepare a new release of BlueBreeze.

This script orchestrates the execution of:
1. update_version.py - Updates version number in podspec
2. fetch_known_uuids.py - Fetches Bluetooth SIG assigned numbers
3. clean_up_copyright.py - Applies copyright headers to all Swift files

Usage:
    python prepare_release.py <version>
    
Example:
    python prepare_release.py 0.1.2
"""

import subprocess
import sys
import re
from pathlib import Path


def run_script(script_name: str, args: list = None) -> bool:
    """
    Run a Python script and return success status.
    
    Args:
        script_name: Name of the script to run
        args: Optional list of arguments to pass to the script
        
    Returns:
        True if the script succeeded, False otherwise
    """
    script_path = Path(__file__).parent / script_name
    
    print(f"\n{'='*60}")
    print(f"Running {script_name}...")
    print('='*60)
    
    try:
        cmd = [sys.executable, str(script_path)]
        if args:
            cmd.extend(args)
        
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=False
        )
        print(f"\n✓ {script_name} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n✗ {script_name} failed with exit code {e.returncode}")
        return False


def main():
    """Main function to run all scripts in sequence."""
    if len(sys.argv) != 2:
        print("Usage: python prepare_release.py <version>")
        print("Example: python prepare_release.py 0.1.2")
        sys.exit(1)
    
    version = sys.argv[1]
    
    # Validate version format (simple check)
    if not re.match(r'^\d+\.\d+\.\d+$', version):
        print(f"✗ Invalid version format: {version}")
        print("Version should be in format: X.Y.Z (e.g., 0.0.19)")
        sys.exit(1)
    
    print(f"Preparing release version {version}...")

    scripts = [
        ("update_version.py", [version]),
        ("fetch_known_uuids.py", None),
        ("clean_up_copyright.py", None),
    ]
    
    success = True
    for script_info in scripts:
        script_name = script_info[0]
        script_args = script_info[1]
        
        if not run_script(script_name, script_args):
            success = False
            break
    
    print(f"\n{'='*60}")
    if success:
        print(f"✓ Release {version} prepared successfully!")
        print(f"\nNext steps:")
        print(f"  1. Review changes: git diff")
        print(f"  2. Commit changes: git add . && git commit -m 'Prepare release {version}'")
        print(f"  3. Tag release: git tag {version}")
        print(f"  4. Push: git push && git push --tags")
    else:
        print("✗ Release preparation failed")
        sys.exit(1)
    print('='*60)


if __name__ == "__main__":
    main()
