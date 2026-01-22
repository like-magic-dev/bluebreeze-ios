"""
Update all generated files and apply copyright headers.

This script orchestrates the execution of:
1. fetch_known_uuids.py - Fetches Bluetooth SIG assigned numbers
2. clean_up_copyright.py - Applies copyright headers to all Swift files

Usage:
    python update_generated_files.py
"""

import subprocess
import sys
from pathlib import Path


def run_script(script_name: str) -> bool:
    """
    Run a Python script and return success status.
    
    Args:
        script_name: Name of the script to run
        
    Returns:
        True if the script succeeded, False otherwise
    """
    script_path = Path(__file__).parent / script_name
    
    print(f"\n{'='*60}")
    print(f"Running {script_name}...")
    print('='*60)
    
    try:
        result = subprocess.run(
            [sys.executable, str(script_path)],
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
    print("Starting automated update process...")
    
    scripts = [
        "fetch_known_uuids.py",
        "clean_up_copyright.py",
    ]
    
    success = True
    for script in scripts:
        if not run_script(script):
            success = False
            break
    
    print(f"\n{'='*60}")
    if success:
        print("✓ All scripts completed successfully!")
    else:
        print("✗ Update process failed")
        sys.exit(1)
    print('='*60)


if __name__ == "__main__":
    main()
