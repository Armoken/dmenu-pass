#!/usr/bin/env python
import argparse
import enum
import fcntl
import glob
import logging
import os
import pathlib
import subprocess
import sys
import time

import dbus

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)-8s %(message)s')


class NotificationType(enum.Enum):
    Info = 0
    Warn = 1
    Error = 2


def get_notify_interface():
    # Check existence of interface
    try:
        dbus.SessionBus().list_names().index("org.freedesktop.Notifications")
    except ValueError:
        logging.warning("D-Bus object for notifications not exists!")
        return

    object = dbus.SessionBus().get_object("org.freedesktop.Notifications",
                                          "/org/freedesktop/Notifications")
    notify_interface = dbus.Interface(object, "org.freedesktop.Notifications")

    return notify_interface


def send_notification_about_success(password_name):
    notify_interface = get_notify_interface()

    icon_name = "dialog-info"
    notify_interface.Notify(  # type: ignore
        "wofi-pass", 0, icon_name,
        "Password in clipboard", "'{}'".format(password_name),
        [], {"urgency": NotificationType.Info.value}, 3000
    )


def send_error_notification(text, return_code):
    notify_interface = get_notify_interface()

    icon_name = "dialog-warning"
    notify_interface.Notify(  # type: ignore
        "wofi-pass", 0, icon_name,
        "Can't find password! (Return code: {})".format(return_code), text,
        [], {"urgency": NotificationType.Warn.value}, 3000
    )


def make_file_descriptor_nonblocking(file_descriptor):
    fd_flags = fcntl.fcntl(file_descriptor, fcntl.F_GETFL)
    fcntl.fcntl(file_descriptor, fcntl.F_SETFL, fd_flags | os.O_NONBLOCK)


def read_from_pipe(pipe):
    data = pipe.read()
    if data is None:
        data = ""
    else:
        data = data.decode().strip()

    return data


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-d", "--dmenu-command", type=str, action="store",
        default="wofi --dmenu --gtk-dark --insensitive",
        help="Command that invokes dmenu-like menu that will be used to show lines."
    )

    args = parser.parse_args()

    return args


def main():
    args = parse_arguments()
    dmenu_command = args.dmenu_command.split(" ")

    password_store_dir = os.environ.get("PASSWORD_STORE_DIR",
                                        "~/.password-store")

    original_paths_to_password_files = sorted(
        glob.glob("**/*.gpg", root_dir=password_store_dir, recursive=True)
    )

    passsword_files = []
    for password_file in original_paths_to_password_files:
        path = pathlib.Path(password_file)
        passsword_files.append(str(path.parent / path.stem))

    password_files_oneline = "\n".join(passsword_files)

    process = subprocess.Popen(
        dmenu_command,
        stdout=subprocess.PIPE,
        stdin=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    selected_password, errors = process.communicate(
        input=password_files_oneline.encode()
    )

    # Pass doesn't trim new line characters, and we need to
    # spaces at the end of names of some passwords. So the only
    # thing that we can do here is newline characters removing
    selected_password = selected_password.decode().replace("\n", "")
    errors = errors.decode().strip()

    if not selected_password:
        return

    process = subprocess.Popen(
        ["pass", "show", "--clip", selected_password],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    while process.poll() is None:
        time.sleep(0.1)  # 0.1 Second

    make_file_descriptor_nonblocking(process.stdout.fileno())
    make_file_descriptor_nonblocking(process.stderr.fileno())

    pass_output = read_from_pipe(process.stdout)
    errors = read_from_pipe(process.stderr)

    if process.returncode == 0:
        send_notification_about_success(selected_password)
    else:
        msg = pass_output + "\n" + errors

        logging.warning(msg)
        send_error_notification(msg, process.returncode)


if __name__ == "__main__":
    sys.exit(main())
