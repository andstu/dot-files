import os
from evdev import InputDevice, categorize, ecodes, list_devices

devices = [InputDevice(path) for path in list_devices()]

for device in devices:
    if device.name == 'HID 04d9:1203':
        dev = device

print(dev)
dev.grab()

for event in dev.read_loop():
  if event.type == ecodes.EV_KEY:
    key = categorize(event)
    if key.keystate == key.key_down:
        print("keycode", key.keycode)
        if key.keycode == 'KEY_KP1':
            os.system('ddcutil -d 2 setvcp 60 0x12')
        if key.keycode == 'KEY_KP2':
            os.system('ddcutil -d 2 setvcp 60 0x0f')
        if key.keycode == 'KEY_KP4':
            os.system('/home/andstu/.macros/input_attach.sh')
        if key.keycode == 'KEY_KP5':
            os.system('/home/andstu/.macros/input_detach.sh')
        if key.keycode == 'KEY_KP7':
            os.system('/home/andstu/.macros/audio_attach.sh')
        if key.keycode == 'KEY_KP8':
            os.system('/home/andstu/.macros/audio_detach.sh')
