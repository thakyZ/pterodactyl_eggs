#!/usr/bin/env python3

# pyright: reportUnknownMemberType=false
# pylint: disable=line-too-long
# cSpell:ignore representer
""" P """

import re
from re import Pattern
import os
from pathlib import Path
from argparse import ArgumentTypeError, Namespace, ArgumentParser
from typing import Any
import yaml
from yaml.dumper import Dumper
import yaml.representer
from yaml.representer import ScalarNode
from yaml import YAMLError

startup_run: bool = str(os.getenv("installing")) == "true"

def validate_bool_str(value: str) -> bool:
    """ P """
    if value.lower() == "true":
        return True
    if value.lower() != "false":
        raise ArgumentTypeError("Argument is not a \"false\" or \"true\" statement.")
    return False

def validate_int(value: str) -> int:
    """ P """
    return int(value, base=10)

def validate_ip_str(value: str) -> str:
    """ P """
    regex: Pattern[str] = re.compile(r"^(?:(?:(?:25[0-5]|(?:2[0-4]|1\d|[1-9]|)\d)(?:\.(?!$)|$)){4}|(?:(?:[a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*(?:[A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])|(?:::01))$")
    if regex.match(value) is None:
        raise ArgumentTypeError("Argument of type ip address does not match a required string")
    return value

def validate_port_str(value: str) -> str:
    """ P """
    temp_int: int = int(value, base=10)
    if temp_int < 255 or temp_int > 65535:
        raise ArgumentTypeError("Argument of type port needs to be greater than 255 and less than 65535")
    return value

def validate_file(value: str) -> Path:
    """ P """
    if not startup_run:
        temp_path: Path = Path(value)
        if temp_path.exists() and temp_path.is_file():
            return temp_path
        else:
            if not temp_path.exists():
                raise ArgumentTypeError(f"File {temp_path} does not exist on the file system.")
            if not temp_path.is_file():
                raise ArgumentTypeError(f"File {temp_path} does not is not a file on the file system.")
            raise ArgumentTypeError(f"File {temp_path} has some other issue on the file system.")
    return Path(value)

def validate_file_exists(value: str) -> Path:
    """ P """
    temp_path: Path = Path(value)
    if temp_path.exists() and temp_path.is_file():
        return temp_path
    if not temp_path.exists():
        raise ArgumentTypeError(f"File {temp_path} does not exist on the file system.")
    if not temp_path.is_file():
        raise ArgumentTypeError(f"File {temp_path} does not is not a file on the file system.")
    raise ArgumentTypeError(f"File {temp_path} has some other issue on the file system.")

def validate_directory_exists(value: str) -> Path:
    """ P """
    temp_path: Path = Path(value)
    if temp_path.exists() and temp_path.is_dir():
        return temp_path
    if not temp_path.exists():
        raise ArgumentTypeError(f"File {temp_path} does not exist on the file system.")
    if not temp_path.is_dir():
        raise ArgumentTypeError(f"File {temp_path} does not is not a directory on the file system.")
    raise ArgumentTypeError(f"File {temp_path} has some other issue on the file system.")

if __name__ == "__main__":
    argparse = ArgumentParser(prog="setup_config", description="Parses arguments from command line and writes to a yaml file.")
    argparse.add_argument("--io", type=validate_file_exists, required=True)
    web_argument_group = argparse.add_argument_group("web", description="")
    web_argument_group.add_argument("--web_password", "-p", type=str, required=True)
    web_argument_group.add_argument("--web_tls", "-t", type=validate_bool_str, required=True)
    web_argument_group.add_argument("--web_cert_path", "-c", type=validate_file, required=False)
    web_argument_group.add_argument("--web_key_path", "-k", type=validate_file, required=False)
    rcon_argument_group = argparse.add_argument_group("rcon", description="")
    rcon_argument_group.add_argument("--rcon_address", "-a", type=validate_ip_str, required=True)
    rcon_argument_group.add_argument("--rcon_port", "-P", type=validate_port_str, required=True)
    rcon_argument_group.add_argument("--rcon_password", "-A", type=str, required=True)
    rcon_argument_group.add_argument("--rcon_timeout", "-T", type=validate_int, required=True)
    rcon_argument_group.add_argument("--rcon_sync_interval", "-s", type=validate_int, required=True)
    save_argument_group = argparse.add_argument_group("save", description="")
    save_argument_group.add_argument("--save_path", "-d", type=validate_directory_exists, required=True)
    save_argument_group.add_argument("--save_decode_path", "-D", type=validate_file_exists, required=True)
    save_argument_group.add_argument("--save_sync_interval", "-S", type=validate_int, required=True)
    args: Namespace = argparse.parse_args()

    config: Path = Path(args.io)

    if not config.exists():
        raise FileNotFoundError(f"The file `config.yaml` was not found at path `{config}`")

    yaml_data: dict[str, Any] | None

    with config.open("r", encoding="utf8") as stream_read:
        yaml_data = yaml.full_load(stream_read)

    if yaml_data is None:
        raise YAMLError("Failed to parse config file.")

    def convert_to_blank_if_none(value: Any | None) -> str:
        """ a """
        if value is None:
            return ""
        return str(value)

    def literal_presenter(dumper: Dumper, data: Any) -> ScalarNode:
        """ a """
        if isinstance(data, str) and "\n" in data:
            return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
        return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="\"")

    yaml_data["web"]["password"] = args.web_password
    yaml_data["web"]["tls"] = args.web_tls
    yaml_data["web"]["cert_path"] = convert_to_blank_if_none(args.web_cert_path)
    yaml_data["web"]["key_path"] = convert_to_blank_if_none(args.web_key_path)
    yaml_data["rcon"]["address"] = f"{args.rcon_address}:{args.rcon_port}"
    yaml_data["rcon"]["password"] = args.rcon_password
    yaml_data["rcon"]["timeout"] = args.rcon_timeout
    yaml_data["rcon"]["sync_interval"] = args.rcon_sync_interval
    yaml_data["save"]["path"] = convert_to_blank_if_none(args.save_path)
    yaml_data["save"]["decode_path"] = convert_to_blank_if_none(args.save_decode_path)
    yaml_data["save"]["sync_interval"] = args.save_sync_interval

    yaml.add_representer(str, literal_presenter)

    with config.open("w", encoding="utf8") as stream_write:
        yaml.dump(yaml_data, stream_write, default_flow_style=False, allow_unicode=True, encoding="utf8")
        stream_write.close()
