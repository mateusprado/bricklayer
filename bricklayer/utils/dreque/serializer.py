import sys
import datetime
import zlib
import decimal
if sys.version_info[:2] >= (2, 6):
    import json
else:
    try:
        import simplejson as json
    except ImportError:
        from django.utils import simplejson as json

DATE_FORMAT = "%Y-%m-%d"
TIME_FORMAT = "%H:%M:%S"
DATETIME_FORMAT = "%s %s" % (DATE_FORMAT, TIME_FORMAT)

class AttributeDict(dict):
    def __getattr__(self, key):
        if key in self:
            return self[key]
        raise AttributeError("'%s' object has no attribute '%s'" % (self.__class__.__name__, key))

class JSONEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, datetime.date) and not isinstance(o, datetime.datetime):
            return {'__type': 'date', '__value': o.strftime(DATE_FORMAT)}
        elif isinstance(o, datetime.datetime):
            value = o.strftime(DATETIME_FORMAT)
            if o.microsecond:
                value += ".%d" % o.microsecond
            return {'__type': 'datetime', '__value': value}
        elif isinstance(o, datetime.time):
            value = o.strftime(TIME_FORMAT)
            if o.microsecond:
                value += ".%d" % o.microsecond
            return {'__type': 'time', '__value': o.strftime(value)}
        elif isinstance(o, decimal.Decimal):
            return str(o)
        elif type(o).__name__ == "__proxy__": # Django's proxy for translatable strings
            return unicode(o)
        return super(JSONEncoder, self).default(o)

class JSONDecoder(json.JSONDecoder):
    def __init__(self, *args, **kwargs):
        kwargs['object_hook'] = self._object_hook
        super(JSONDecoder, self).__init__(*args, **kwargs)

    def _object_hook(self, o):
        typ = o.get('__type')
        if typ:
            value = o.get('__value')
            if typ == 'datetime':
                dt = datetime.datetime.strptime(value.split('.')[0], DATETIME_FORMAT)
                if '.' in value:
                    dt = dt.replace(microsecond=int(value.split('.')[-1]))
                return dt
            elif typ == 'date':
                return datetime.datetime.strptime(value, DATE_FORMAT).date()
            elif typ == 'time':
                dt = datetime.datetime.strptime(value.split('.')[0], TIME_FORMAT).time()
                if '.' in value:
                    dt = dt.replace(microsecond=int(value.split('.')[-1]))
                return dt
            raise TypeError("Unable to deserialize unknown type %s" % typ)
        return AttributeDict(o)

def dumps(*args, **kwargs):
    kwargs['cls'] = JSONEncoder
    kwargs['indent'] = False
    st = json.dumps(*args, **kwargs)
    return zlib.compress(st)

def loads(st, *args, **kwargs):
    st = zlib.decompress(st)
    kwargs['cls'] = JSONDecoder
    return json.loads(st, *args, **kwargs)
    