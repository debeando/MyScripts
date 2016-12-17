#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging

logging.basicConfig(filename="logs.log", level=logging.DEBUG)

logging.debug("This is a debug message")
logging.info("Informational message")
logging.error("An error has happened!")
