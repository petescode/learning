'''
Author: Pete Wood
Purpose: Calculate a file's hash, then compare it to a given hash to verify integrity
Notes:
    - This is a learning program - comments will be verbose!
    - Developed in Python 3.7
    - Designed to work on both Linux and Windows
    - Using "i" for "item" in for loops regardless of list name

Links:
    - https://stackoverflow.com/questions/7099290/how-to-ignore-hidden-files-using-os-listdir
        For defining function to find hidden files (not top answer)

    - https://stackoverflow.com/questions/13954841/sort-list-of-strings-ignoring-upper-lower-case
        Sorting list of strings and ignoring case sensitivity, see bottom answers

    - https://realpython.com/working-with-files-in-python/
    - https://www.geeksforgeeks.org/file-searching-using-python/
        Filename pattern matching and searching
    
    - https://wiki.python.org/moin/WhileLoop
        Used as reference for while true loop


DEVELOPMENT:
    - case insensitive filename pattern matching
    - how to exclude hidden directories from search?
'''

# for clearing screen
# for parsing filesystem
import os

# for filename pattern matching when searching for files in a directory
import fnmatch 

# if os.name is "nt" it is windows, else if os.name is "posix" it is Linux
# os.system is used to make system calls to the specific OS
def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

clear_screen()

# should exclude hidden directories (ones that start with ".")
def dir_is_hidden(dir):
    return dir.startswith(".")

# get list (array-like thing in python) of directories (to parse later for the file to hash)
# os.path.expanduser is best here because it will use environment variables to get the user's home directory, regardless of lin/win
home_list = os.listdir(os.path.expanduser('~'))

# create an empty list
dir_list = []

# for each item in home_list, ignore if dir is hidden, else (if not hidden) add the item to our new list
for i in home_list:
    if(dir_is_hidden(i)):
        #print(i)
        pass
    else:
        dir_list.append(i)

# this actually sorts AND writes changes to the list at the same time
dir_list.sort(key=str.casefold)


#print("\nWhere is the file to be hashed?")
#print()
#print("     DIRECTORIES     ")
#print("---------------------")

#count = 0
#for i in dir_list:
#    count += 1
#    print(count, i)

# need a select/input statement here


# INSTEAD, let's just try searching a whole filesystem tree for a filename pattern match

#for file in os.listdir(os.path.expanduser('~')):
#    if fnmatch.fnmatch(file, '*.txt'):
#        print(file)

#for i in home_list:
#    print(i)

#for file in os.listdir('/home/'):
#    if fnmatch.fnmatch(file, '*.txt'):
#        print(file)

# how to make this case insensitive? see test "centos" vs "CentOS"
search_param = input("\nEnter pattern to search for:\n")
print()

list_with_path = []
list_without_path = []

home_dir = os.path.expanduser('~')
#for root, dirs, files in os.walk('/home/'):
for root, dirs, files in os.walk(home_dir):
    for file in files:
        #if fnmatch.fnmatch(file, "*.iso"):
        if fnmatch.fnmatch(file, search_param):
            list_with_path.append(root + '/' + file)
            list_without_path.append(file)

#for i in list_with_path:
#    print(i)

#for i in list_without_path:
#    print(i)

count = 0
for i in list_with_path:
    count += 1
    print(count, i)

# with a while True loop, it only breaks if you specify break...
#   otherwise, it will continue to loop when you say continue
# here we are also catching ValueErrors (happen when expects int but doesn't get a number)
while True:
    try:
        choice = int(input("\nSelect a file: "))
    except ValueError:
        #print("Invalid input! Try again.")
        continue
    if(choice > 0 and choice <= (len(list_with_path))):
        break
    else:
        continue

choice = list_with_path[choice-1]

#print(choice)
clear_screen()