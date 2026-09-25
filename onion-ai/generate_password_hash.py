#!/usr/bin/env python3
"""
Password Hash Generator Utility for Onion AI.
Allows generating secure bcrypt hashes for configuration in .env.
Usage:
    python generate_password_hash.py
    python generate_password_hash.py <optional_password>
"""
import sys
import getpass
import bcrypt

def generate_hash(password: str) -> str:
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(password.encode("utf-8"), salt)
    return hashed.decode("utf-8")

def main():
    if len(sys.argv) > 1:
        pwd = sys.argv[1]
    else:
        try:
            pwd = getpass.getpass("Enter password to hash: ")
        except (KeyboardInterrupt, EOFError):
            print("\nAborted.")
            sys.exit(1)

    if not pwd:
        print("Error: Password cannot be empty.")
        sys.exit(1)

    hash_str = generate_hash(pwd)
    print("\nBcrypt Password Hash (copy into .env):")
    print(hash_str)

if __name__ == "__main__":
    main()
