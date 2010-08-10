import ConfigParser

class BrickConfigImpl:
    _instance = None
    _config_file = None
    def __init__(self, configfile=None):
        self._config_file = configfile
        if not configfile:
            self._config_file = '/etc/bricklayer/bricklayer.ini'
        self.config_parse = ConfigParser.ConfigParser()
        self.config_parse.read([self._config_file])

    def get(self, section, name):
        return self.config_parse.get(section, name)

#    def getFromFile(self, file, section, name):
#        return self.config_parse.get(section, name)

def BrickConfig(configfile=None):
    if not BrickConfigImpl._instance:
        BrickConfigImpl._instance = BrickConfigImpl(configfile)

    return BrickConfigImpl._instance
