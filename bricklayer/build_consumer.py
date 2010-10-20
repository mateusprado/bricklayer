import sys
import os
import bricklayer
sys.path.append(os.path.join(os.path.dirname(bricklayer.__file__), 'utils'))
sys.path.append(os.path.dirname(bricklayer.__file__))

from bricklayer.builder import Builder as builder
from bricklayer.config import BrickConfig
from dreque import DrequeWorker

def main():
    config_file = '/etc/bricklayer/bricklayer.ini'
    if os.environ.has_key('BRICKLAYERCONFIG'):
        config_file = os.environ['BRICKLAYERCONFIG']
    BrickConfig(config_file)
    
    worker = DrequeWorker(['build'], '127.0.0.1')
    worker.work()

if __name__ == "__main__":
    main()
