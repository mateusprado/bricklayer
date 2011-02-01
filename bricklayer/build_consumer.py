import sys
import os
import bricklayer
sys.path.append(os.path.join(os.path.dirname(bricklayer.__file__), 'utils'))
sys.path.append(os.path.dirname(bricklayer.__file__))

from bricklayer.builder import build_project
from bricklayer.config import BrickConfig
from dreque import DrequeWorker

def main():
    brickconfig = BrickConfig()
    worker = DrequeWorker(['build'], brickconfig.get('redis', 'redis-server'))
    worker.work()

if __name__ == "__main__":
    main()
