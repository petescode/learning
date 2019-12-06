# clear the screen
# if Linux, then if Windows

import os   # for clearing screen

print(os.name)

# if os.name is "nt" it is windows, else if os.name is "posix" it is Linux
def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

clear_screen()

print("Hello world!")
