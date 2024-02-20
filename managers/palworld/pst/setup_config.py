#!/usr/bin/env python3

# pyright: reportUnknownMemberType=false
# pylint: disable=line-too-long
# cSpell:ignore representer
""" Temporary Module Docstring """

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
from typing import Optional

startup_run: bool = str(os.getenv("installing")) == "true"

class Quoted(str):
    """ Temporary Class Docstring """
    pass

def validate_bool_str(value: str) -> bool:
    """ Temporary Method Docstring """
    if value.lower() == "true":
        return True
    if value.lower() != "false":
        raise ArgumentTypeError("Argument is not a \"false\" or \"true\" statement.")
    return False

def validate_int(value: str) -> int:
    """ Temporary Method Docstring """
    return int(value, base=10)

def validate_ip_str(value: str) -> str:
    """ Temporary Method Docstring """
    regex: Pattern[str] = re.compile(r"^(?:(?:(?:25[0-5]|(?:2[0-4]|1\d|[1-9]|)\d)(?:\.(?!$)|$)){4}|(?:(?:[a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*(?:[A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])|(?:::01))$")
    if regex.match(value) is None:
        raise ArgumentTypeError("Argument of type ip address does not match a required string")
    return value

def validate_port_str(value: str) -> str:
    """ Temporary Method Docstring """
    temp_int: int = int(value, base=10)
    if temp_int < 255 or temp_int > 65535:
        raise ArgumentTypeError("Argument of type port needs to be greater than 255 and less than 65535")
    return value

def validate_file(value: str) -> Path:
    """ Temporary Method Docstring """
    return Path(value)
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
    """ Temporary Method Docstring """
    return Path(value)
    temp_path: Path = Path(value)
    if temp_path.exists() and temp_path.is_file():
        return temp_path
    if not temp_path.exists():
        raise ArgumentTypeError(f"File {temp_path} does not exist on the file system.")
    if not temp_path.is_file():
        raise ArgumentTypeError(f"File {temp_path} does not is not a file on the file system.")
    raise ArgumentTypeError(f"File {temp_path} has some other issue on the file system.")

def validate_directory_exists(value: str) -> Path:
    """ Temporary Method Docstring """
    return Path(value)
    temp_path: Path = Path(value)
    if temp_path.exists() and temp_path.is_dir():
        return temp_path
    if not temp_path.exists():
        raise ArgumentTypeError(f"File {temp_path} does not exist on the file system.")
    if not temp_path.is_dir():
        raise ArgumentTypeError(f"File {temp_path} does not is not a directory on the file system.")
    raise ArgumentTypeError(f"File {temp_path} has some other issue on the file system.")

def convert_to_blank_if_none(value: Optional[Any]) -> str:
    """ Temporary Method Docstring """
    if value is None:
        return Quoted("")
    return Quoted(str(value))

def quoted_presenter(dumper: Dumper, data: Any) -> ScalarNode:
    """ Temporary Method Docstring """
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')

def main():
    """ Temporary Method Docstring """
    yaml.add_representer(Quoted, quoted_presenter)
    argparse = ArgumentParser(prog="setup_config", description="Parses arguments from command line and writes to a yaml file.")
    argparse.add_argument("--io", type=validate_file_exists, required=True)
    web_argument_group = argparse.add_argument_group("web", description="")
    web_argument_group.add_argument("--web_password", "-p", type=str, required=False)
    web_argument_group.add_argument("--web_tls", "-t", type=validate_bool_str, required=False)
    web_argument_group.add_argument("--web_cert_path", "-c", type=validate_file, required=False)
    web_argument_group.add_argument("--web_key_path", "-k", type=validate_file, required=False)
    web_argument_group.add_argument("--web_trusted_proxy", "-b", nargs='+', type=validate_ip_str, required=False)
    web_argument_group.add_argument("--web_broadcast_address", "-B", type=validate_ip_str, required=False)
    rcon_argument_group = argparse.add_argument_group("rcon", description="")
    rcon_argument_group.add_argument("--rcon_address", "-a", type=validate_ip_str, required=False)
    rcon_argument_group.add_argument("--rcon_port", "-P", type=validate_port_str, required=False)
    rcon_argument_group.add_argument("--rcon_password", "-A", type=str, required=False)
    rcon_argument_group.add_argument("--rcon_timeout", "-T", type=validate_int, required=False)
    rcon_argument_group.add_argument("--rcon_sync_interval", "-s", type=validate_int, required=False)
    save_argument_group = argparse.add_argument_group("save", description="")
    save_argument_group.add_argument("--save_path", "-d", type=validate_directory_exists, required=False)
    save_argument_group.add_argument("--save_decode_path", "-D", type=validate_file_exists, required=False)
    save_argument_group.add_argument("--save_sync_interval", "-S", type=validate_int, required=False)
    args: Namespace = argparse.parse_args()

    config: Path = Path(args.io)

    if not config.exists():
        raise FileNotFoundError(f"The file `config.yaml` was not found at path `{config}`")

    yaml_data: Optional[dict[str, Any]] = None

    with config.open("r", encoding="utf8") as stream_read:
        yaml_data = yaml.full_load(stream_read)

    if yaml_data is None:
        raise YAMLError("Failed to parse config file.")

    if args.web_password is not None:
        yaml_data["web"]["password"] = Quoted(args.web_password)
    if args.web_tls is not None:
        yaml_data["web"]["tls"] = args.web_tls
    if args.web_trusted_proxy is not None:
        yaml_data["web"]["trusted_proxy"] = args.web_trusted_proxy
    if args.web_broadcast_address is not None and isinstance(args.web_broadcast_address, list) and len(args.web_broadcast_address) > 0:
        yaml_data["web"]["broadcast_address"] = args.web_broadcast_address
    if args.web_cert_path is not None:
        yaml_data["web"]["cert_path"] = convert_to_blank_if_none(args.web_cert_path)
    if args.web_key_path is not None:
        yaml_data["web"]["key_path"] = convert_to_blank_if_none(args.web_key_path)
    if args.rcon_address is not None and args.rcon_port is not None:
        yaml_data["rcon"]["address"] = Quoted(f"{args.rcon_address}:{args.rcon_port}")
    elif args.rcon_address is not None:
        current_port = yaml_data["rcon"]["address"].split(":")[1]
        yaml_data["rcon"]["address"] = Quoted(f"{args.rcon_address}:{current_port}")
    elif args.rcon_port is not None:
        current_address = yaml_data["rcon"]["address"].split(":")[0]
        yaml_data["rcon"]["address"] = Quoted(f"{current_address}:{args.rcon_port}")
    if args.rcon_password is not None:
        yaml_data["rcon"]["password"] = args.rcon_password
    if args.rcon_timeout is not None:
        yaml_data["rcon"]["timeout"] = args.rcon_timeout
    if args.rcon_sync_interval is not None:
        yaml_data["rcon"]["sync_interval"] = args.rcon_sync_interval
    if args.save_path is not None:
        yaml_data["save"]["path"] = convert_to_blank_if_none(args.save_path)
    if args.save_decode_path is not None:
        yaml_data["save"]["decode_path"] = convert_to_blank_if_none(args.save_decode_path)
    if args.save_sync_interval is not None:
        yaml_data["save"]["sync_interval"] = args.save_sync_interval

    with config.open("w", encoding="utf8") as stream_write:
        yaml.dump(yaml_data, stream_write, default_flow_style=False, allow_unicode=True, encoding="utf8")
        stream_write.close()

if __name__ == "__main__":
    main()
