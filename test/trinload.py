#!/usr/bin/env python2
#
# Test sending code to TrinLoad running on SAM

import os, sys
import struct
import socket
import datetime
import argparse

HOST, PORT = "<broadcast>", 0xedb0

parser = argparse.ArgumentParser(description="Send executable code to a networked SAM")
parser.add_argument('-p', '--page', action='store', type=int, default=1, help="override start HMPR page (default=1)")
parser.add_argument('-a', '--addr', action='store', type=int, default=0x8000, help="override execute address (default=0x8000)")
parser.add_argument('file', action='store')
args = parser.parse_args()


def read_file (path, block_size=1024):
	with open(path, 'rb') as f:
		while True:
			chunk = f.read(block_size)
			if chunk:
				yield chunk
			else:
				return


sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

sock.settimeout(1);
sock.sendto("?", (HOST, PORT))

try:
	received = sock.recvfrom(2)

	if received[0] == "!":
		print "Sending to SAM at {}".format(received[1][0])

		page = 1
		offset = 0
		outstanding = 0
		max_outstanding = 4

		for chunk in read_file(args.file, 1468):
			header = struct.pack('<sBH', "@", page, offset)
			sock.sendto(header+chunk, (received[1][0], PORT))
			outstanding += 1

			if outstanding >= max_outstanding:
				ack = sock.recvfrom(4)
				outstanding -= 1

			offset += len(chunk)
			if offset >= 0x4000:
				offset -= 0x4000
				page += 1

		while outstanding:
			ack = sock.recvfrom(4)
			outstanding -= 1

		header = struct.pack('<sBH', "X", args.page, args.addr)
		sock.sendto(header, (received[1][0], PORT))

except socket.timeout, e:
	print "Timed out waiting for response."
