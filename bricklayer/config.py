import ConfigParser

class BrickConfig:
    config_file = '/etc/bricklayer/bricklayer.ini'
    def __init__(self):
        self.config_parse = ConfigParser.ConfigParser()
        self.config_parse.read([self.config_file])

    def get(self, section, name):
        return self.config_parse.get(section, name)
