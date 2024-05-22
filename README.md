# waf_encrypt

## Overview
This script automates the process of generating SSL/TLS certificates using [LeGo with UltraDNS](https://github.com/ultradns/lego) to perform the DNS challenge. After generating the certificates, the script uploads them along with their private keys to UltraWAF, Vercara's web application firewall product. This tool's intent is to help streamline the management of SSL certificates for domains managed by Vercara's infrastructure.

## Prerequisites
1. **LeGo CLI**: Ensure that the LeGo CLI is installed in your environment. [Installation instructions can be found here](https://go-acme.github.io/lego/).
2. **jq**: This script uses `jq` for parsing JSON. Install it using your package manager, e.g., `sudo apt-get install jq` for Ubuntu or `brew install jq` for macOS.
3. **curl**: Needed for making HTTP requests from the command line.

## Configuration
The script uses a JSON configuration file (`config.json`) to manage its settings. An example is provided.

- **domain**: Array of domains for which to generate and manage certificates.
- **email**: Email address used for registration with Let's Encrypt.
- **udns_uname**, **udns_pw**: Credentials for UltraDNS.
- **uwaf_id**, **uwaf_secret**: Credentials used to authenticate to the UltraWAF API.

## Usage
1. **Prepare Configuration**: Edit `config.json` with the appropriate values as described above.
2. **Run the Script**: Make the script executable then run it:
   ```
   chmod +x waf_encrypt.sh
   ./waf_encrypt.sh
   ```
   The script will handle all steps automatically, from generating certificates to uploading them to UltraWAF.

## Operational Notes
- The script should be run in a secure environment, as it handles sensitive keys and credentials.
- Ensure that all dependencies are properly installed and accessible in your system's PATH.
- The script includes automatic acceptance of Let's Encrypt's TOS; ensure this is acceptable for your use case.
- A `name` of the certificate will be appended with a UID to prevent conflict when uploading, this is a truncated hash of a timestamp and random characters.

## Support
For issues or enhancements, contact the support team at Vercara or submit an issue via the GitHub repository.
