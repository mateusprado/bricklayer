from config import BrickConfig

print BrickConfig('./config/bricklayer.ini').get('databases', 'uri')
