#!/usr/bin/env python3
import plistlib
from contextlib import suppress

types = plistlib.load(open("/System/Library/CoreServices/CoreTypes.bundle/Contents/Info.plist", "rb"))

models = []
for uttype in types['UTExportedTypeDeclarations']:
    with suppress(KeyError):
        model = uttype['UTTypeTagSpecification']['com.apple.device-model-code']
        if isinstance(model, str):
            models.append(model)
        else:
            models.extend(model)
fmt = ""
i = 4
models.sort()
prev = models[0][:i]

for model in models:
    if prev != (prev:=model[:i]):
        fmt += "\n\n"
    fmt += f"{model}, "

print(fmt)
