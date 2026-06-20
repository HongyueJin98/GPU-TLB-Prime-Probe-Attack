#!/usr/bin/python3

import socket
import time 
import subprocess
import os
import sys

'''
websites = [
    "www.adobe.com", "www.amazon.com", "www.android.com", "www.archive.org", "www.bing.com",
    "www.bit.ly", "www.canva.com", "www.chase.com", "www.chatgpt.com", "www.cloudflare.com",
    "www.digicert.com", "www.discord.com", "www.dropbox.com", "www.duckduckgo.com", "www.ebay.com",
    "www.epicgames.com", "www.facebook.com", "www.fastly.net", "www.forbes.com", "www.foxnews.com",
    "www.github.com", "www.github.io", "www.gmail.com", "www.google.com", "www.health.mil",
    "www.icloud.com", "www.instagram.com", "www.intuit.com", "www.medium.com", "www.mozilla.org",
    "www.msn.com", "www.netflix.com", "www.opera.com", "www.outlook.com", "www.paypal.com",
    "www.reddit.com", "www.sciencedirect.com", "www.sharepoint.com", "www.skype.com", "www.snapchat.com",
    "www.unity3d.com", "www.vimeo.com", "www.whatsapp.com", "www.wikipedia.org", "www.windows.com",
    "www.wordpress.com", "www.wordpress.org", "www.cnn.com", "www.x.com", "www.youtube.com"
]
'''
#some website for quick test
websites = ["www.google.com", "www.facebook.com", "www.bing.com", "www.wikipedia.org",]
#server ip and port
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = '130.127.106.32' 
server_port = 12344 
client_socket.connect((server_address, server_port))

#number of loops
num = 1000
for i in range(num):
  for web in websites:
    #path for recording files
    name = web + "_" + str(i+47) + ".txt"
    sss = web.encode('utf-8')
    client_socket.send(sss)
    time.sleep(6)
    print('prime probe on' + web)

    with open(name, 'w') as file:
      a_out = subprocess.Popen(["./xyz"], stdout = file)
      while True:
        if os.path.exists("signal.txt"):
          break
      client_socket.send(sss)

      #kill the prime probe using dummy after 10s
      try:
        a_out.wait(timeout=10)
      except subprocess.TimeoutExpired:
        #run 2 s
        b_out = subprocess.Popen(["./dummy"])
        b_out.wait()
      
      print('\tprime probe end')
      b_out = subprocess.run(["rm", "signal.txt"])
      client_socket.send(sss)
      time.sleep(5)
      
client_socket.close()

