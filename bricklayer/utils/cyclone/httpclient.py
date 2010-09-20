#!/usr/bin/env python
# coding: utf-8
#
# Copyright 2010 Alexandre Fiori
# based on the original Tornado by Facebook
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

from twisted.internet import reactor
from twisted.internet.defer import Deferred
from twisted.internet.protocol import Protocol
from zope.interface import implements
from twisted.internet.defer import succeed
from cyclone.tw.client import Agent
from cyclone.tw.http_headers import Headers
from cyclone.tw.iweb import IBodyProducer
from cyclone.web import _utf8

agent = Agent(reactor)

class StringProducer(object):
    implements(IBodyProducer)

    def __init__(self, body):
        self.body = body
        self.length = len(body)

    def startProducing(self, consumer):
        consumer.write(self.body)
        return succeed(None)

    def pauseProducing(self): pass
    def stopProducing(self): pass


class Receiver(Protocol):
    def __init__(self, finished):
        self.finished = finished
        self.data = []

    def dataReceived(self, bytes):
        self.data.append(bytes)

    def connectionLost(self, reason):
        self.finished.callback("".join(self.data))

    
class HTTPClient(object):
    def __init__(self, url, *args, **kwargs):
        self._args = args
        self._kwargs = kwargs
        self.url = url
        
        self.method = self._kwargs.get("method","GET")
        self.headers = self._kwargs.get("headers")
        self.body = self._kwargs.get("postdata")
        
        self.response = None
        if self.body:
            self.body_producer = StringProducer(self.body)
        else:
            self.body_producer = None
        
    def fetch(self):
        d = agent.request(
            self.method,
            self.url,
            Headers(self.headers),
            self.body_producer)
        d.addCallbacks(self._response, self._error)
        return d
    
    def _error(self, *args, **kwargs):
        print args,kwargs
        
    def _response(self, response):
        self.response = response
        self.response.error = None
        self.response.headers = dict(self.response.headers.getAllRawHeaders())
        finished = Deferred()
        response.deliverBody(Receiver(finished))
        def _add_body(body):
            response.body = body
            response.request = self
            return response
        finished.addCallback(_add_body)
        return finished


def fetch(url, *args, **kwargs):
    url = _utf8(url)
    c = HTTPClient(url,*args, **kwargs)
    d = c.fetch()
    return d
