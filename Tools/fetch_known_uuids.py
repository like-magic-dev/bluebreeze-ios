import subprocess
import shutil
import yaml
import os

REPO_URL = "https://bitbucket.org/bluetooth-SIG/public.git"

# Clone the bluetooth SIG repository
print("Cloning the Bluetooth SIG repository...")
if os.path.exists("bluetooth_repo"):
    print("Removing existing repository...")
    shutil.rmtree("bluetooth_repo")
subprocess.run(["git", "clone", REPO_URL, "bluetooth_repo"], check=True)

# Generate Swift file
print("Generating Swift file...")
OUTPUT = "BlueBreeze/BBAssignedNumbers.swift"

with open(OUTPUT, "w", encoding="utf-8") as output_file:
    output_file.write("//\n")
    output_file.write("// Copyright (c) Like Magic e.U. and contributors. All rights reserved.\n")
    output_file.write("// Licensed under the MIT license. See LICENSE file in the project root for details.\n")
    output_file.write("//\n")
    output_file.write(f"// Auto-generated from Bluetooth SIG repository {REPO_URL}\n")
    output_file.write("// Do not edit directly.\n")
    output_file.write("//\n\n")
    output_file.write("import Foundation\n")
    output_file.write("import CoreBluetooth\n")
    output_file.write("//\n")
    output_file.write("public class BBAssignedNumbers {\n")
    
    # Export all service UUIDs
    print("Parsing service UUIDs...")
    with open("bluetooth_repo/assigned_numbers/uuids/service_uuids.yaml", "r", encoding="utf-8") as input_file:
        service_uuids_data = yaml.safe_load(input_file)

        print("Exporting service UUIDs...")

        output_file.write("    /// Bluetooth SIG service UUIDs\n")
        output_file.write("    public static let serviceUUIDs: [BBUUID: String] = [\n")
        service_uuids = sorted(service_uuids_data["uuids"], key=lambda x: x["uuid"])
        for item in service_uuids:
            uuid = item["uuid"]
            name = item["name"]

            formatted_value = f"{uuid:04X}"
            escaped_name = name.replace('"', '\\"')

            output_file.write(f'        BBUUID(string: "{formatted_value}"): "{escaped_name}",\n')

        output_file.write("    ]\n\n")

    # Export all characteristic UUIDs
    print("Parsing characteristic UUIDs...")
    with open("bluetooth_repo/assigned_numbers/uuids/characteristic_uuids.yaml", "r", encoding="utf-8") as input_file:
        characteristic_uuids_data = yaml.safe_load(input_file)

        print("Exporting characteristic UUIDs...")

        output_file.write("    /// Bluetooth SIG characteristic UUIDs\n")
        output_file.write("    public static let characteristicUUIDs: [BBUUID: String] = [\n")
        characteristic_uuids = sorted(characteristic_uuids_data["uuids"], key=lambda x: x["uuid"])
        for item in characteristic_uuids:
            uuid = item["uuid"]
            name = item["name"]

            formatted_value = f"{uuid:04X}"

            escaped_name = name.replace('"', '\\"')
            escaped_name = escaped_name.replace("\\textsubscript{2}", "2")

            output_file.write(f'        BBUUID(string: "{formatted_value}"): "{escaped_name}",\n')

        output_file.write("    ]\n\n")

    # Export all company identifiers
    print("Parsing company identifiers...")
    with open("bluetooth_repo/assigned_numbers/company_identifiers/company_identifiers.yaml", "r", encoding="utf-8") as input_file:
        company_ids_data = yaml.safe_load(input_file)

        print("Exporting company identifiers...")

        output_file.write("    /// Bluetooth SIG assigned company identifiers\n")
        output_file.write("    public static let companyIdentifiers: [UInt16: String] = [\n")
        company_ids = sorted(company_ids_data["company_identifiers"], key=lambda x: x["value"])
        for item in company_ids:
            value = item["value"]
            name = item["name"]

            formatted_value = f"0x{value:04X}"
            escaped_name = name.replace('"', '\\"')

            output_file.write(f'        {formatted_value}: "{escaped_name}",\n')

        output_file.write("    ]\n\n")

    output_file.write("}\n")

print(f"Generated {OUTPUT}")

# Clean up the bluetooth_repo folder
print("Cleaning up...")
shutil.rmtree("bluetooth_repo")
