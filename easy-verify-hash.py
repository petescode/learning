'''
Author: Pete Wood
Purpose: Calculate a file's hash, then compare it to a given hash to verify integrity
Notes:
    - This is a learning program - comments will be verbose!
    - Developed in Python 3.7
    - Designing this to work on both Linux and Windows - not tested on Windows at this time
    - Using "i" for "item" in for loops regardless of list name
    - Searching for files is case-sensitive and literal (not wildcarded on either side of search);
        this is expected behavior for *nix, but is different than the ps1 version of this script

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
    
    - https://docs.python.org/3/library/hashlib.html
    - http://pythoncentral.io/hashing-files-with-python/
        Hashing files in Python
        Use hashlib.algorithms_guaranteed in addition to
            hashlib.algorithms_available for better understanding of RIPEMD160


DEVELOPMENT:
    - case insensitive filename pattern matching
    - input validation for "enter pattern..." (including when nothing is entered)
    - how to exclude hidden directories from search? 
'''

import os       # for clearing screen, parsing filesystem
import fnmatch  # for filename pattern matching when searching for files in a directory
import hashlib  # for hashing

# if os.name is "nt" it is windows, else if os.name is "posix" it is Linux
# os.system is used to make system calls to the specific OS
def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

clear_screen()

# should exclude hidden directories (ones that start with ".")
def dir_is_hidden(dir):
    return dir.startswith(".")

# get list of directories (to parse later for the file to hash)
# os.path.expanduser is best here because it will use environment variables to get the user's home directory, regardless of lin/win
home_list = os.listdir(os.path.expanduser('~'))

# create an empty list
dir_list = []

# for each item in home_list, ignore if dir is hidden, else (if not hidden) add the item to our new list
for i in home_list:
    if(dir_is_hidden(i)):
        pass
    else:
        dir_list.append(i)

# this actually sorts AND writes changes to the list at the same time
dir_list.sort(key=str.casefold)



# NEEDS REFINING
# how to make this case insensitive? see test "centos" vs "CentOS"
# need some input validation on this
search_param = input("\nEnter pattern to search for:\n")
print()


#if search_param and search_param.isspace():
#    # string not empty
#    print("string is not empty")
#else:
#    # string is empty
#    print("string is empty")


list_with_path = []
list_without_path = []

home_dir = os.path.expanduser('~')
for root, dirs, files in os.walk(home_dir):
    for file in files:
        if fnmatch.fnmatch(file, search_param):
            list_with_path.append(root + '/' + file)
            list_without_path.append(file)

count = 0
for i in list_with_path:
    count += 1
    print(count, i)

# with a while True loop, it only breaks if you specify break...
#   otherwise, it will continue to loop when you say continue
# here we are also catching ValueErrors (happen when expects int but doesn't get a number)
while True:
    try:
        choice = int(input("\nMake a selection: "))
    except ValueError:
        #print("Invalid input! Try again.")
        continue
    if(choice > 0 and choice <= (len(list_with_path))):
        break
    else:
        continue

file_with_path = list_with_path[choice-1]

# declare two variables at once (results of the os.path.split() operation)
file_dir, file_name = os.path.split(file_with_path)
file_dir = file_dir + "/"

# get size of file and round to 2 decimal places
file_size_bytes = os.path.getsize(file_with_path)
file_size_kb = round((file_size_bytes / 1024),2)
file_size_mb = round((file_size_bytes / 1024 / 1024),2)
file_size_gb = round((file_size_bytes / 1024 / 1024 / 1024),2)

# convert file size from bytes to appropriate human-readable output
# using f-strings to get variable and text string in the same line
if file_size_bytes >= 1073741824:
    # this is at least 1GB in size
    file_size = f"{file_size_gb} GB"

elif 1048576 <= file_size_bytes < 1073741824:
    # this should be in MB
    file_size = f"{file_size_mb} MB"

elif 1048576 > file_size_bytes >= 1024:
    # this should be in KB
    file_size = f"{file_size_kb} KB"

else:
    file_size = f"{file_size_bytes} Bytes"


clear_screen()

algorithms = ["MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160"]

print("\nYour file is:\n", file_with_path)
print()
print("   HASH ALGORITHMS   ")
print("---------------------")
count = 0
for i in algorithms:
    count += 1
    print(count, i)


BLOCKSIZE = 65536
# while true loop keeps looping unless it hits a 'break'
# this means that only the options presented will be accepted as input
while True:
    algorithm = input("\nChoose an algorithm: ")

    if algorithm == '1':
        chosen_algorithm = "MD5"
        print("\n\nMD5 hash:")
        hasher = hashlib.md5()
        with open(file_with_path, 'rb') as afile:
            buf = afile.read(BLOCKSIZE)
            while len(buf) > 0:
                hasher.update(buf)
                buf = afile.read(BLOCKSIZE)
            hash_generated = hasher.hexdigest()
            print("", hash_generated)
            print()
            break

    elif algorithm == '2':
        chosen_algorithm = "SHA1"
        print("\n\nSHA1 hash:")
        hasher = hashlib.sha1()
        with open(file_with_path, 'rb') as afile:
            buf = afile.read(BLOCKSIZE)
            while len(buf) > 0:
                hasher.update(buf)
                buf = afile.read(BLOCKSIZE)
            hash_generated = hasher.hexdigest()
            print("", hash_generated)
            print()
            break

    elif algorithm == '3':
        chosen_algorithm = "SHA256"
        print("\n\nSHA256 hash:")
        hasher = hashlib.sha256()
        with open(file_with_path, 'rb') as afile:
            buf = afile.read(BLOCKSIZE)
            while len(buf) > 0:
                hasher.update(buf)
                buf = afile.read(BLOCKSIZE)
            hash_generated = hasher.hexdigest()
            print("", hash_generated)
            print()
            break

    elif algorithm == '4':
        chosen_algorithm = "SHA384"
        print("\n\nSHA384 hash:")
        hasher = hashlib.sha384()
        with open(file_with_path, 'rb') as afile:
            buf = afile.read(BLOCKSIZE)
            while len(buf) > 0:
                hasher.update(buf)
                buf = afile.read(BLOCKSIZE)
            hash_generated = hasher.hexdigest()
            print("", hash_generated)
            print()
            break

    elif algorithm == '5':
        chosen_algorithm = "SHA512"
        print("\n\nSHA512 hash:")
        hasher = hashlib.sha512()
        with open(file_with_path, 'rb') as afile:
            buf = afile.read(BLOCKSIZE)
            while len(buf) > 0:
                hasher.update(buf)
                buf = afile.read(BLOCKSIZE)
            hash_generated = hasher.hexdigest()
            print("", hash_generated)
            print()
            break

    # note here how the 'hasher' variable was done differently
    elif algorithm == '6':
        chosen_algorithm = "RIPEMD160"
        print("\n\nRIPEMD160 hash:")
        hasher = hashlib.new('ripemd160')
        with open(file_with_path, 'rb') as afile:
            buf = afile.read(BLOCKSIZE)
            while len(buf) > 0:
                hasher.update(buf)
                buf = afile.read(BLOCKSIZE)
            hash_generated = hasher.hexdigest()
            print("", hash_generated)
            print()
            break


# hashes are often provided in all caps
# .strip() strips out whitespaces ONLY on either side of the string
# this prevents false mismatch due to user input error
hash_provided = input("Enter the hash you were provided: ").lower().strip()

clear_screen()

if hash_generated == hash_provided:
    print("\nCheck SUCCEEDED: Hashes match!")
    print("____________________________________________________")
    print("Compiled hash:", hash_generated)
    print("Provided hash:", hash_provided)
    print("\n\nAlgorithm: ", chosen_algorithm)
    print("Path:      ", file_dir)
    print("File:      ", file_name)
    print("Size:      ", file_size)
    print("\n")
else:
    print("\nCheck FAILED: Hashes DO NOT match!")
    print("____________________________________________________")
    print("Compiled hash:", hash_generated)
    print("Provided hash:", hash_provided)
    print("\n\nAlgorithm: ", chosen_algorithm)
    print("Path:      ", file_dir)
    print("File:      ", file_name)
    print("Size:      ", file_size)
    print("\n")