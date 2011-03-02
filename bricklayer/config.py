import os
import ConfigParser

class BrickConfigImpl:
    _instance = None
    config_file = None
    def __init__(self):
        self.config_parse = ConfigParser.ConfigParser()
        self.config_parse.read([self.config_file])

    def get(self, section, name):
        return self.config_parse.get(section, name)

def BrickConfig(configfile=None):
    if configfile == None:
        if "BRICKLAYERCONFIG" in os.environ.keys():
            configfile = os.environ['BRICKLAYERCONFIG']
        else:
            configfile = '/etc/bricklayer/bricklayer.ini'

    if not BrickConfigImpl._instance:
        BrickConfigImpl.config_file = configfile
        BrickConfigImpl._instance = BrickConfigImpl()

    return BrickConfigImpl._instance
