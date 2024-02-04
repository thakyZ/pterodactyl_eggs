#!/usr/bin/env python3

""" Download the latest release assets from GitHub """

import json
import os
from pathlib import Path
from re import Pattern
import re
from argparse import Action, ArgumentParser, ArgumentError, Namespace
import urllib.request as urllib
import requests

repo_argument: Action
output_argument: Action
file_argument: Action

def validate_url(value: str) -> list[str]:
    """ validates the github url. """
    site, path = value.split(":")
    user, repo = path.split("/")
    if site != "gh":
        raise ArgumentError(repo_argument, "repo is not a valid github argument")
    return [site, user, repo]

def validate_dir(value: str) -> Path:
    """ validates the directory to output assets to. """
    temp_path: Path = Path(value)
    if not temp_path.exists():
        os.makedirs(temp_path, exist_ok=True)
    elif not temp_path.is_dir():
        raise ArgumentError(output_argument, "Output directory is not a directory.")
    return temp_path

def validate_regex(value: str) -> Pattern[str]:
    """ validates the directory to output assets to. """
    if value.startswith("r'") and value.endswith("'"):
        return re.compile(value.removeprefix("r'").removesuffix("'"))
    return re.compile(re.escape(value))

def fetch_api_key() -> str:
    """ fetches api key from file named '.env' in the same directory as the script """
    script_dir = Path(os.path.dirname(os.path.realpath(__file__)))
    env_file = Path(os.path.join(script_dir, ".env"))

    output: str = ""

    with env_file.open("r", encoding="utf8") as fr:
        output = fr.readline()
        fr.close()
    return output

if __name__ == "__main__":

    argparse = ArgumentParser(prog="download_latest", description="Download the latest release assets from GitHub")
    repo_argument = argparse.add_argument("--repo", "-r", type=validate_url, required=True)
    output_argument = argparse.add_argument("--output_dir", "-o", dest="output", type=validate_dir, required=True)
    file_argument = argparse.add_argument("--file", "-f", nargs="+", dest="assets", help="<Required> Set flag", type=validate_regex, required=True)
    args: Namespace = argparse.parse_args()

    api_key: str = fetch_api_key().rstrip()

    url: str = f"http://api.github.com/repos/{args.repo[1]}/{args.repo[2]}/releases"
    headers: dict[str, str] = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {api_key}",
        "X-GitHub-Api-Version": "2022-11-28"
    }

    response = requests.get(url, headers=headers, timeout=10000)
    json_data = json.loads(response.content.decode(response.apparent_encoding))
    to_dl_assets: dict[str, str] = {}

    reg: Pattern[str]
    for reg in args.assets:
        for asset in json_data[0]["assets"]:
            if reg.match(asset["name"]) is not None:
                to_dl_assets[asset["name"]] = asset["browser_download_url"]

    for item, url in to_dl_assets.items():
        download_file = urllib.urlretrieve(url, Path(os.path.join(args.output, item)))
