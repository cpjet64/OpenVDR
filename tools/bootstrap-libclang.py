"""Install the pinned Windows libclang wheel's DLL and notices locally."""

import hashlib
import io
from pathlib import Path
import urllib.request
import zipfile

URL = ("https://files.pythonhosted.org/packages/0b/2d/"
       "3f480b1e1d31eb3d6de5e3ef641954e5c67430d5ac93b7fa7e07589576c7/"
       "libclang-18.1.1-py2.py3-none-win_amd64.whl")
SHA256 = "4dd2d3b82fab35e2bf9ca717d7b63ac990a3519c7e312f19fa8e86dcc712f7fb"
DEST = Path(__file__).resolve().parent.parent / "deps" / "libclang-18.1.1"


def main():
    if DEST.exists():
        raise SystemExit(f"Destination already exists: {DEST}; inspect it before retrying.")
    with urllib.request.urlopen(URL, timeout=120) as response:
        wheel = response.read()
    if hashlib.sha256(wheel).hexdigest() != SHA256:
        raise SystemExit("Wheel SHA-256 mismatch; nothing extracted.")
    with zipfile.ZipFile(io.BytesIO(wheel)) as archive:
        names = archive.namelist()
        dlls = [name for name in names if name.lower().endswith('/libclang.dll')]
        notices = [name for name in names if '.dist-info/' in name and
                   ('license' in name.rsplit('/', 1)[-1].lower() or
                    'notice' in name.rsplit('/', 1)[-1].lower())]
        if len(dlls) != 1 or not notices:
            raise SystemExit("Unexpected wheel contents; nothing extracted.")
        DEST.mkdir(parents=True)
        (DEST / 'libclang.dll').write_bytes(archive.read(dlls[0]))
        for name in notices:
            (DEST / Path(name).name).write_bytes(archive.read(name))
    print(f"Verified libclang and notices installed at {DEST}")


if __name__ == '__main__':
    main()
