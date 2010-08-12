from config import BrickConfig

#bleh = BrickConfig('./config/bricklayer.ini').get('workspace', 'dir')

print BrickConfig('./config/bricklayer.ini').get('databases', 'uri')
#print BrickConfig('./config/bricklayer.ini').get('databases', 'uri')
#print BrickConfig('./config/bricklayer.ini').get('databases', 'uri')
