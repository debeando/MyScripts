#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import smtplib

TO      = 'nicola@heygo.com'
SUBJECT = 'TEST MAIL'
TEXT    = 'Here is a message from python.'

# Gmail Sign In
gmail_sender = 'print@heygo.com'
smtp_server   = 'email-smtp.eu-west-1.amazonaws.com'
smtp_user     = 'AKIAI6KDYVIRVKNWQVTQ'
smtp_password = 'AnnaJ73Vghfnv6Zqi+b0zbMjO+a9axEVCHMneEquJS8Z'

server = smtplib.SMTP(smtp_server, 25)
server.ehlo()
server.starttls()
server.login(smtp_user, smtp_password)

BODY = '\r\n'.join(['To: %s' % TO,
                    'From: %s' % gmail_sender,
                    'Subject: %s' % SUBJECT,
                    '', TEXT])

try:
    server.sendmail(gmail_sender, [TO], BODY)
    print ('email sent')
except:
    print ('error sending mail')

server.quit()
