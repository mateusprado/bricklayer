# Copyright (c) 2001-2008 Twisted Matrix Laboratories.
# See LICENSE for details.

"""
Resource traversal integration with L{twisted.cred} to allow for
authentication and authorization of HTTP requests.
"""

# Expose HTTP authentication classes here.
from cyclone.tw._auth.wrapper import HTTPAuthSessionWrapper
from cyclone.tw._auth.basic import BasicCredentialFactory
from cyclone.tw._auth.digest import DigestCredentialFactory

__all__ = [
    "HTTPAuthSessionWrapper",

    "BasicCredentialFactory", "DigestCredentialFactory"]
